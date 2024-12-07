# == Schema Information
#
# Table name: shipping_methods
#
#  id                           :integer          not null, primary key
#  shipping_type                :integer
#  active                       :boolean          default(TRUE), not null
#  name                         :string(255)
#  delivery_minimum             :float            default(0.0), not null
#  delivery_threshold           :float
#  delivery_fee                 :float            default(0.0), not null
#  delivery_expectation         :string(255)
#  allows_scheduling            :boolean          default(TRUE), not null
#  scheduled_interval_size      :integer          default(120)
#  supplier_id                  :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  maximum_delivery_expectation :integer          default(60), not null
#  hours_config                 :text
#  same_day_delivery            :boolean          default(FALSE), not null
#  cut_off                      :string(20)
#  requires_scheduling          :boolean          default(FALSE), not null
#  allows_tipping               :boolean          default(TRUE), not null
#  deleted_at                   :datetime
#  shipping_flat_fee            :boolean          default(FALSE)
#
# Indexes
#
#  index_shipping_methods_on_deleted_at   (deleted_at)
#  index_shipping_methods_on_supplier_id  (supplier_id)
#  shipping_methods_shipping_type_idx     (shipping_type)
#

class ShippingMethod < ActiveRecord::Base
  include FormatDateTime
  include Schedule

  acts_as_paranoid
  has_paper_trail

  # These describe specific field requirements which must be present
  # on an order for the shipping method to be considered valid.
  ORDERING_REQUIREMENTS = {
    on_demand: ['ship_address_id'],
    next_day: ['ship_address_id'],
    shipped: ['ship_address_id'],
    pickup: ['pickup_detail_id'],
    digital: []
  }.freeze

  # These describe the time we should create a supplier comment (in minutes) for
  # orderes placed during operating hours. If an order has not been confirmed
  # then an automatic supplier comment will be triggered.
  AUTOMATIC_SUPPLIER_COMMENT_TIMES = {
    on_demand: 15,
    pickup: 15,
    shipped: 2880,
    digital: 0 # what do we use here?
  }.freeze

  # These describe the time we should create an Asana unconfirmed task (in minutes) for
  # orderes placed during operating hours. If an order has not been confirmed
  # then an asana unconfirmed task will be triggered.
  CREATE_UNCONFIRMED_ASANA_TASK_TIMES = {
    on_demand: 20,
    pickup: 20,
    shipped: 4320,
    digital: 0 # what do we use here?
  }.freeze

  # These describe the required order confirmation times (in minutes) for
  # orderes placed during operating hours. If an order has not been confirmed
  # then an alert will be triggered to cx.
  CONFIRMATION_TIMES = {
    on_demand: 14,
    next_day: 14,
    pickup: 14,
    shipped: 180,
    digital: 0 # what do we use here?
  }.freeze

  IN_STORE_SHIPPING_TYPES = %i[
    shipped
    pickup
    on_demand
  ].freeze

  enum shipping_type: { on_demand: 0, next_day: 1, shipped: 2, pickup: 3, digital: 4 }
  serialize :hours_config
  time_zone_method :supplier_timezone

  belongs_to :supplier, touch: true, inverse_of: :shipping_methods
  has_many :delivery_expectation_exceptions
  has_one :delivery_expectation_exception, -> { active.order(:id) }, inverse_of: false
  has_many :delivery_zones, dependent: :destroy
  has_many :delivery_breaks, ->(obj) { where('? = ANY(delivery_breaks.shipping_method_ids)', obj.id) }, through: :supplier

  delegate :active,                 to: :supplier, allow_nil: true, prefix: true
  delegate :name,                   to: :supplier, allow_nil: true, prefix: true
  delegate :next_scheduling_window, to: :scheduler
  delegate :promo?,                 to: :supplier, allow_nil: true, prefix: true
  delegate :scheduling_windows,     to: :scheduler
  delegate :supplier_type_id,       to: :supplier, allow_nil: true
  delegate :timezone,               to: :supplier, allow_nil: true, prefix: true
  delegate :upcoming_holidays,      to: :supplier, allow_nil: true
  delegate :upcoming_holidays_by_shipping_type, to: :supplier, allow_nil: true

  scope :active,        -> { where(active: true) }
  scope :not_on_demand, -> { where.not(shipping_type: 0) }
  scope :digital,       -> { where(shipping_type: shipping_types[:digital]) }
  scope :not_digital,   -> { where.not(shipping_type: shipping_types[:digital]) }
  scope :on_demand,     -> { where(shipping_type: 0) }
  scope :optimal_order, -> { order(:shipping_type, :delivery_minimum, :delivery_fee) }
  scope :trackable,     -> { where(shipping_type: [ShippingMethod.shipping_types[:shipped], ShippingMethod.shipping_types[:pickup]]) }
  scope :regions,       lambda {
                          joins(supplier: [{ region: :state }])
                            .where(shipping_methods: { active: true })
                            .where(regions: { visible: true })
                            .order('states.name', 'regions.name', 'regions.slug', 'shipping_methods.shipping_type')
                            .distinct
                            .pluck('states.name', 'regions.name', 'regions.slug', 'shipping_methods.shipping_type', 'regions.id')
                        }

  validates :delivery_expectation, presence: true
  validates :delivery_fee,         presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :delivery_minimum,     presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :on_demand_consistency
  validate :validate_delivery_hours

  accepts_nested_attributes_for :delivery_breaks, reject_if: proc { true } # Just allows the form to render

  before_save :deactivate_delivery_zones, if: :active_changed?

  #------------------------------------------------------------
  # Class methods
  #------------------------------------------------------------
  def self.possible_delivery_expectations
    ['Delivery under an hour',
     'Delivery in 60-120 minutes',
     'Delivery in 60-90 minutes',
     'Delivery in 90-120 minutes',
     'Delivery in 2-2.5 hours',
     'Delivery in 2.5-3 hours',
     'Shipment',
     'Shipment (1-3 business days)',
     'Shipment (2 business days)',
     'Shipment (3-7 business days)',
     'Usually ships within 1-2 business days',
     'In-store pickup']
  end

  #------------------------------------------------------------
  # Instance methods
  #------------------------------------------------------------
  def confirmation_time
    confirmation_time = CONFIRMATION_TIMES[shipping_type.to_sym]
    confirmation_time += 5 if supplier.automated_confirmation_reminders?
    confirmation_time
  end

  def automatic_supplier_comment_time
    return 40 if on_demand? && delivery_expectation == 'Delivery in 60-120 minutes'

    AUTOMATIC_SUPPLIER_COMMENT_TIMES[shipping_type.to_sym]
  end

  def create_unconfirmed_asana_task_time
    CREATE_UNCONFIRMED_ASANA_TASK_TIMES[shipping_type.to_sym]
  end

  def delivery_hours_grouped
    to_meridian = ->(time) { Time.zone.parse(time).strftime('%I:%M %P') }
    unpack      = ->(times) { Array(times).flatten.map(&to_meridian) }
    to_day      = ->(wday, times, id) { DeliveryHours.new(wday, unpack[times], id) }

    if hours_config.present?
      hours, _count = DeliveryHours.days_of_week.inject([{}, 0]) do |(config, count), wday|
        [
          config.merge!(wday => (hours_config[wday] || [nil]).map do |hours_config_wday|
            day = to_day[wday, hours_config_wday, count]
            count = count.to_i + 1
            day
          end),
          count
        ]
      end

      hours
    end
  end

  def delivery_hours
    delivery_hours_grouped&.values&.flatten
  end

  def delivery_hours=(hours)
    parse_time = ->(time) { Time.zone.parse(time)&.to_s(:time) }

    self[:hours_config] = hours && hours.values.inject({}) do |config, day|
      starts_at = parse_time.call(day['starts_at'])
      ends_at   = parse_time.call(day['ends_at'])
      hours     = starts_at && ends_at ? { starts_at => ends_at } : {}
      wday      = day['wday'].to_sym

      hours_arr = (config && config[wday]) || {}
      config.merge!(wday => hours_arr.merge(hours))
    end
  end

  def upcoming_breaks
    parse_time = ->(time) { Time.zone.parse(time).to_s(:time) }

    Time.use_zone(supplier_timezone) do
      delivery_breaks
        .upcoming
        .pluck(:date, :start_time, :end_time)
        .inject({}) do |breaks, (date, start_time, end_time)|
          breaks.merge!(Time.zone.parse(date).to_date => { parse_time[start_time] => parse_time[end_time] })
        end
    end
  end

  def next_delivery_stale_at
    # Supplier is open and on-demand delivery is an option
    return opening_hours.closes_at if opening_hours.open? && on_demand?

    # Supplier is closed and orders can't be scheduled
    return opening_hours.opens_at  if opening_hours.closed? && !allows_scheduling

    # Scheduling is the best option (supplier open or closed)
    # * We need to also handle the case where there was not a valid next scheduling
    #   window (e.g. store is only open 10 minutes and is configured for 60 minute
    # .  windows) - In this case we allow the result to be valid for 5 minutes.
    next_scheduling_window ? next_scheduling_window[:start_time] : Time.zone.now + 5.minutes
  end

  def get_delivery_expectation
    (delivery_expectation_exception || self).delivery_expectation
  end

  def get_maximum_delivery_expectation
    (delivery_expectation_exception || self).maximum_delivery_expectation
  end

  def delivery_expectation_exception?
    delivery_expectation_exception.present?
  end

  def next_delivery
    if digital?
      ''
    elsif shipped?
      name
    elsif opening_hours.open? && on_demand? && requires_scheduling
      format_opening_time(next_scheduling_window[:start_time])
    elsif opening_hours.open? && on_demand?
      format_max_time(get_maximum_delivery_expectation, supplier.timezone)
    elsif opening_hours.open? && pickup?
      format_max_time(get_maximum_delivery_expectation, supplier.timezone, false)
    elsif opening_hours.opens_at
      format_opening_time(opening_hours.opens_at)
    else
      # This is an edge case where a store is indefinately on holiday
      'Not available'
    end
  end

  def covers_address?(address)
    delivery_zones.active.any? { |dz| dz.contains?(address) }
  end

  def hours_config
    super || supplier&.hours_config
  end

  def opening_hours
    @opening_hours ||= OpeningHoursService.new(schedule: schedule, time_zone: supplier.canonical_time_zone)
  end

  def scheduling_mode
    if allows_scheduling?
      next_day? || requires_scheduling ? 'always' : 'optional'
    else
      'never'
    end
  end

  def always_open?
    # For the time being, we assume if the type is `shipped`, then we are always open. Later on we may wish
    # to extend this definition to allow 24/7 opening hours for the other shipping methods.
    shipped?
  end

  def closes_at(time = Time.zone.now.in_time_zone(supplier.timezone))
    opening_hours.closes_at(time)
  end

  def opens_at(time = Time.zone.now.in_time_zone(supplier.timezone))
    opening_hours.opens_at(time)
  end

  def open?(time = Time.zone.now.in_time_zone(supplier.timezone))
    opening_hours.open?(time)
  end

  def closed?(time = Time.zone.now.in_time_zone(supplier.timezone))
    opening_hours.closed?(time)
  end

  def trackable?
    pickup? || shipped?
  end

  private

  def deactivate_delivery_zones
    return if active

    delivery_zones.active.update_all(active: false)
  end

  def scheduler
    @scheduler ||= SchedulingService.new(
      schedule: schedule,
      time_zone: canonical_time_zone,
      duration: scheduled_interval_size,
      breaks: upcoming_breaks,
      promo: supplier_promo?,
      cut_off: cut_off.presence,
      same_day: same_day_delivery
    )
  end

  def on_demand_consistency
    errors.add(:delivery_expectation, 'Cannot be in-store pickup for On-demand') if shipping_type == 'on_demand' && delivery_expectation == 'In-store pickup'
  end

  def validate_delivery_hours
    if delivery_hours.present?
      delivery_hours.each do |hours|
        errors.add(:delivery_hours, "ends at must be greater than starts at for #{hours.wday}") if hours.ends_at.present? && hours.starts_at.present? && hours.ends_at.to_time <= hours.starts_at.to_time
      end
    end
  end
end
