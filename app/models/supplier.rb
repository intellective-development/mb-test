# == Schema Information
#
# Table name: suppliers
#
#  id                             :integer          not null, primary key
#  name                           :string(255)      not null
#  email                          :string(255)
#  created_at                     :datetime
#  updated_at                     :datetime
#  active                         :boolean          default(FALSE), not null
#  minibar_percent                :decimal(8, 4)
#  braintree_merchant_account_id  :string(255)
#  supplier_type_id               :integer
#  last_inventory_update_at       :datetime
#  timezone                       :string(255)      default("America/New_York")
#  score                          :float
#  trak_id                        :string(255)
#  delegate_supplier_id           :integer
#  inventory_token                :string(255)
#  inventory_token_activated_at   :datetime
#  boost_factor                   :integer          default(0)
#  temporary_boost_factor         :integer          default(0)
#  region_id                      :integer
#  origin_sales_tax_deprecated    :boolean          default(FALSE), not null
#  skip_state_shipping_tax        :boolean          default(FALSE), not null
#  permalink                      :string(255)
#  invoicing_enabled              :boolean          default(TRUE), not null
#  config                         :json
#  display_name                   :string(255)
#  integrated_inventory           :boolean          default(FALSE)
#  allow_dtc_overlap              :boolean          default(TRUE), not null
#  delivery_service_id            :integer
#  custom_ca_crv                  :boolean          default(FALSE)
#  delivery_service_config_id     :integer
#  onfleet_organization           :string
#  onfleet_autoassign_team        :string
#  order_note                     :string
#  import_stale_file_time_frame   :integer          default(1)
#  delivery_service_customer      :string
#  delivery_service_client_id     :string
#  delivery_service_client_secret :string
#  birthdate_required             :boolean
#  external_supplier_id           :string
#  allow_substitution             :boolean          default(TRUE), not null
#  manual_inventory               :boolean          default(FALSE)
#  emails                         :string           default([]), is an Array
#  dashboard_type                 :string           default("MINIBAR")
#  notify_no_tracking_number      :boolean          default(FALSE)
#  show_substitution_ok           :boolean          default(TRUE), not null
#  delegate_invoice_supplier_id   :integer
#  external_availability          :boolean          default(TRUE), not null
#  activated_at                   :date
#  deactivated_at                 :date
#  parent_id                      :integer
#  engraving                      :boolean          default(FALSE), not null
#  daily_shipping_limit           :integer
#  lb_retailer_id                 :integer
#  daily_shipping_count           :integer          default(0)
#  accepts_back_orders            :boolean          default(FALSE)
#  presale_eligible               :boolean          default(FALSE)
#  fulfillment_system             :integer
#  ss_api_key_ciphertext          :text
#  ss_api_secret_ciphertext       :text
#  ss_active                      :boolean          default(FALSE), not null
#  import_config                  :json
#  legacy_rb_paypal_supported     :boolean          default(FALSE), not null
#  supports_graphic_engraving     :boolean          default(FALSE)
#  exclude_minibar_storefront     :boolean          default(FALSE)
#  closed_hours_effective         :boolean          default(FALSE)
#  secondary_delivery_service_id  :integer
#  deactivated_by_id              :bigint(8)
#  deactivated_reason             :string
#  tdlinx_code                    :string
#
# Indexes
#
#  index_suppliers_on_checkout_fields               (id,active,deactivated_at,braintree_merchant_account_id) WHERE ((active = true) AND (deactivated_at IS NULL) AND (braintree_merchant_account_id IS NOT NULL))
#  index_suppliers_on_deactivated_by_id             (deactivated_by_id)
#  index_suppliers_on_delegate_invoice_supplier_id  (delegate_invoice_supplier_id)
#  index_suppliers_on_delegate_supplier_id          (delegate_supplier_id)
#  index_suppliers_on_delivery_service_config_id    (delivery_service_config_id)
#  index_suppliers_on_parent_id                     (parent_id)
#  index_suppliers_on_region_id                     (region_id)
#  index_suppliers_on_supplier_type_id              (supplier_type_id)
#  index_suppliers_on_trak_id                       (trak_id)
#  suppliers_dashboard_type_idx                     (dashboard_type)
#  suppliers_external_supplier_id_idx               (external_supplier_id)
#  suppliers_name_idx                               (name)
#  suppliers_permalink_idx                          (permalink)
#
# Foreign Keys
#
#  fk_rails_...  (deactivated_by_id => users.id)
#  fk_rails_...  (delegate_invoice_supplier_id => suppliers.id)
#  fk_rails_...  (delivery_service_config_id => delivery_service_configs.id)
#  fk_rails_...  (delivery_service_id => delivery_services.id)
#  fk_rails_...  (parent_id => suppliers.id)
#

# TODO: Would love to re-consider usage of hstore for settings here.

class Supplier < ActiveRecord::Base
  extend FriendlyId
  include CreateUuid
  include Schedule
  include Supplier::Hours
  include Supplier::InventoryManagement
  include Supplier::Notifications
  include Supplier::Routing
  include Supplier::DashboardType
  include WisperAdapter

  friendly_id :permalink_candidates, use: %i[slugged finders history], slug_column: :permalink
  # This is required due to the following issues in friendly_id 5.2.0
  # https://github.com/norman/friendly_id/issues/765
  alias_attribute :slug, :permalink

  has_paper_trail ignore: %i[created_at updated_at settings score permalink last_inventory_update_at]

  acts_as_taggable_on :regions

  time_zone_method :timezone

  has_many :data_feeds # BC: hey this is weird, should be has_one
  has_many :shipping_methods, dependent: :destroy, inverse_of: :supplier
  has_many :delivery_zones, through: :shipping_methods
  has_many :employed_users, through: :employees, source: :user
  has_many :employees, dependent: :destroy
  has_many :supplier_holidays, dependent: :destroy
  has_many :holidays, through: :supplier_holidays
  has_many :invoice_tiers
  has_many :notification_methods
  has_many :order_adjustments
  has_many :order_survey_suppliers
  has_many :order_surveys, through: :order_survey_suppliers
  has_many :orders, through: :shipments, inverse_of: :order_suppliers
  has_many :reports, class_name: 'SupplierReport'
  has_many :shipments
  has_many :variants
  has_many :inventories, through: :variants
  has_many :products, through: :variants
  has_many :product_size_groupings, through: :variants
  has_many :delivery_breaks, dependent: :destroy
  has_many :supplier_breaks, class_name: 'SupplierBreak'
  has_many :supplier_external_breaks, class_name: 'SupplierExternalBreak'
  has_many :supplier_feature_items
  has_many :feature_items, through: :supplier_feature_items
  has_many :supplier_logos
  has_many :business_suppliers
  has_many :supplier_ship_states
  has_many :ship_engine_carrier_accounts, dependent: :destroy
  has_many :packages, through: :shipments
  has_many :custom_tags
  has_many :package_size_presets, dependent: :destroy

  has_one :address, as: :addressable, dependent: :destroy
  has_one :profile, class_name: 'SupplierProfile'
  has_one :three_jms_credential, class_name: 'Supplier::ThreeJMSCredential', dependent: :destroy
  has_one :ship_station_credential, class_name: 'Supplier::ShipStationCredential', dependent: :destroy

  has_many :supplier_facebook_caches, class_name: 'SupplierFacebookCache'

  has_and_belongs_to_many :fulfillment_services

  # TODO: Be careful with this one, address will determine this.
  has_one :default_shipping_method, -> { optimal_order }, class_name: 'ShippingMethod'
  has_one :state, through: :address, source: :state
  belongs_to :region, inverse_of: :suppliers
  belongs_to :supplier_type
  belongs_to :delivery_service
  belongs_to :secondary_delivery_service, class_name: 'DeliveryService'
  belongs_to :delivery_service_config

  belongs_to :deactivated_by, class_name: 'User'
  belongs_to :parent, class_name: 'Supplier'
  has_many :child_suppliers, class_name: 'Supplier', foreign_key: 'parent_id'

  # A supplier may delegate various responsibilities to another supplier. Currently this includes:
  #
  #   * Payments  - When using the get_braintree_merchant_account_id method it will return
  #                 the delegate's id. BRAINTREE ONLY.
  #   * Employees - When using get_employees method, the delegates employees will be returned.
  #   * Shipments - When using get_shipments, the shipments for the supplier plus any which have
  #                 delegated orders will be returned.
  #
  # Primary usecase for this feature is in the event that you wish to run a promotion, or offer shipping,
  # from a supplier but wish to have unique delivery zones, hours, minimums, delivery fees etc.
  # This gives the flexibility without complicating the payments or notifications side of things.
  belongs_to :delegate, class_name: 'Supplier', foreign_key: 'delegate_supplier_id', inverse_of: :delegate_suppliers
  has_many :delegate_suppliers, class_name: 'Supplier', foreign_key: 'delegate_supplier_id', inverse_of: :delegate

  belongs_to :delegate_invoice, class_name: 'Supplier', foreign_key: 'delegate_invoice_supplier_id', inverse_of: :delegate_invoice_suppliers
  has_many :delegate_invoice_suppliers, class_name: 'Supplier', foreign_key: 'delegate_invoice_supplier_id', inverse_of: :delegate_invoice

  # Not 100% sure about these
  has_many :volume_discounts, as: :subject
  has_many :deals, as: :subject

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :delivery_breaks, reject_if: :delivery_break_attribute_blank?, allow_destroy: true
  accepts_nested_attributes_for :invoice_tiers
  accepts_nested_attributes_for :notification_methods, reject_if: proc { |attributes| attributes['value'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :profile
  accepts_nested_attributes_for :ship_station_credential, reject_if: proc { |attributes| attributes['api_secret'].blank? }

  delegate :categories,           to: :profile, allow_nil: true
  delegate :deferrable?,          to: :supplier_type, allow_nil: true
  delegate :delivery_expectation, to: :default_shipping_method, allow_nil: true
  delegate :delivery_fee,         to: :default_shipping_method, allow_nil: true
  delegate :delivery_minimum,     to: :default_shipping_method, allow_nil: true
  delegate :delivery_threshold,   to: :default_shipping_method, allow_nil: true
  delegate :name,                 to: :region,        allow_nil: true, prefix: true
  delegate :promo?,               to: :supplier_type, allow_nil: true
  delegate :state_name,           to: :address,       allow_nil: true
  delegate :tag_list,             to: :profile,       allow_nil: true
  delegate :tags,                 to: :profile,       allow_nil: true
  delegate :type_hierarchy,       to: :profile,       allow_nil: true
  delegate :hierarchy_type_ids,   to: :profile,       allow_nil: true
  delegate :apple_pay_supported,  to: :profile,       allow_nil: true

  after_create :create_profile
  after_create :create_city_in_region!

  after_save :after_save_actions
  after_save :create_supplier_product_order_limits_on_activating_presale_eligibility
  after_save :destroy_supplier_product_order_limits_on_deactivating_presale_eligibility

  validates :name,   presence: true,
                     length: { maximum: 255 }
  validates :email,  format: { with: CustomValidators::Emails.email_validator },
                     allow_nil: true,
                     length: { maximum: 255 }
  validates :emails, enum: { format: { with: CustomValidators::Emails.email_validator },
                             length: { maximum: 255 } }

  validates :boost_factor, inclusion: { in: -10..10 }
  validates :temporary_boost_factor, inclusion: { in: -10..10 }

  validates :lb_retailer_id, length: { is: 6 }, numericality: { only_integer: true }, allow_nil: true
  validates :daily_shipping_limit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validate :ensure_no_loop_on_delegate_invoice_suppliers

  scope :active,        -> { where(active: true) }
  scope :inactive,      -> { where(active: false) }
  scope :wine_spirits,  -> { where(supplier_type_id: SupplierType.find_by(name: 'Wine & Spirits')) }
  scope :beer_grocery,  -> { where(supplier_type_id: SupplierType.find_by(name: 'Beer & Mixers')) }
  scope :matching_name, ->(name) { where('lower(suppliers.name) LIKE ?', "%#{name}%") }
  scope :by_permalink,  ->(permalinks) { where(permalink: permalinks) }
  # TODO: This doesn't account for suppliers delegating to another - we should account for it
  # in this scope.
  scope :braintree,     -> { where.not(braintree_merchant_account_id: nil) }
  scope :with_shipping_tax, -> { where(skip_state_shipping_tax: false) }
  scope :in_state, ->(state_id) { active.joins(:address).where('addresses.state_id = ?', state_id) }
  scope :digital, -> { joins(:shipping_methods).merge(ShippingMethod.digital) }
  scope :not_digital, -> { joins(:shipping_methods).merge(ShippingMethod.not_digital) }
  scope :vineyard_select, -> { joins(:region).where(regions: { name: 'Vineyard Select' }) }
  scope :minibar_fees, -> { find_by(permalink: Business.find_by(id: Business::MINIBAR_ID).fee_supplier_permalink) }
  scope :included_on_minibar_storefront, -> { where(exclude_minibar_storefront: false) }

  #-----------------------------------
  # Class methods
  #-----------------------------------
  def self.admin_grid(params = {})
    # Default to showing active suppliers.
    params[:active] = true unless params[:active].present? || params[:inactive]

    grid = Supplier.order(:name, :id)
    grid = grid.where('lower(suppliers.name) LIKE ?', "%#{params[:name].downcase}%") if params[:name].present?
    grid = grid.where('suppliers.email LIKE ?', "#{params[:email]}%") if params[:email].present?
    grid = grid.active if params[:active].present? && params[:inactive].blank?
    grid = grid.inactive if params[:inactive].present? && params[:active].blank?
    grid = grid.none if params[:inactive].blank? && params[:active].blank?

    case params[:supplier_issue]
    when 'no_active_shipping_method'
      active_sm_ids = Supplier.where(id: grid.pluck(:id).uniq).joins(:shipping_methods)
                              .where(shipping_methods: { active: true })
      grid = grid.where.not(id: active_sm_ids.pluck(:id))
    when 'no_active_delivery_zone'
      active_dz_ids = Supplier.where(id: grid.pluck(:id).uniq).joins(:delivery_zones)
                              .where(delivery_zones: { active: true })
      digital_supplier_ids = Supplier.digital.pluck(:id)
      grid = grid.where.not(id: (active_dz_ids.pluck(:id) + digital_supplier_ids))
    end

    grid
  end

  def self.eligible_for_pre_sale_shipment(shipment)
    return [] if shipment.nil? || shipment.address.nil?
    return [] unless shipment.customer_placement_pre_sale?
    return [] unless shipment.pre_sale?

    pre_sale_product = shipment.order_items.last.product

    return [] if pre_sale_product.product_trait.nil?

    joins(:variants, supplier_ship_states: :ship_category)
      .joins('join pre_sales on variants.product_id = pre_sales.product_id')
      .where('suppliers.presale_eligible = ?', true)
      .where('supplier_ship_states.states::jsonb ? :state_abbr_name', state_abbr_name: shipment.address.state_abbr_name)
      .where(supplier_ship_states: { ship_categories: { name: pre_sale_product.product_trait.ship_category } })
      .where('pre_sales.status = ?', 'active')
      .where('variants.deleted_at is null')
      .where('variants.product_id = ?', pre_sale_product.id)
      .order(name: :asc)
  end

  def permalink_candidates
    [
      [display_name],
      [display_name, address&.city, state&.abbreviation],
      [display_name, '-', :uuid]
    ]
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------
  ### DELEGATE METHODS
  def get_braintree_merchant_account_id
    braintree_merchant_account_id || delegate&.braintree_merchant_account_id
  end

  def get_shipments
    delegatees = Supplier.where(delegate_supplier_id: id).pluck(:id)
    Shipment.where(supplier_id: delegatees << id).order(created_at: :desc)
  end

  def get_invoice_shipments(business_id, begin_date, end_date)
    return get_reservebar_invoice_shipments(business_id, begin_date, end_date) unless business_id == Business::MINIBAR_ID

    delegatees = Supplier.where(delegate_invoice_supplier_id: id).pluck(:id)
    storefronts = Storefront.where(business_id: business_id).pluck(:id)
    Shipment.where(
      supplier_id: delegatees << id
    ).includes(:order, :supplier, :shipment_amount)
            .joins(:order)
            .where(
              state: ShipmentStateMachine::INVOICABLE_STATES,
              orders: {
                created_at: begin_date...end_date,
                storefront_id: storefronts
              }
            )
            .order(created_at: :desc)
  end

  def get_reservebar_invoice_shipments(business_id, begin_date, end_date)
    delegatees = Supplier.where(delegate_invoice_supplier_id: id).pluck(:id)
    storefronts = Storefront.where(business_id: business_id).pluck(:id)
    Shipment.where(
      supplier_id: delegatees << id,
      state: ShipmentStateMachine::INVOICABLE_STATES,
      confirmed_at: begin_date...end_date
    ).includes(:order, :supplier, :shipment_amount)
            .joins(:order)
            .where(orders: { storefront_id: storefronts })
            .order(created_at: :desc)
  end

  def get_employees
    delegate ? delegate.employees : employees
  end

  def get_supplier
    delegate || self
  end
  ### END DELEGATE METHODS

  # TODO: Decide if we want to keep this longer term,
  def get_setting(key)
    config.fetch(String(key), false)
  end

  def delivery_break_attribute_blank?(attributes)
    %w[start_time end_time date].any? { |attribute| attributes[attribute].blank? }
  end

  def upcoming_breaks
    parse_time = ->(time) { Time.zone.parse(time).to_s(:time) }

    Time.use_zone(timezone) do
      delivery_breaks
        .where('ARRAY[?]::integer[] <@ delivery_breaks.shipping_method_ids', shipping_method_ids)
        .upcoming
        .pluck(:date, :start_time, :end_time)
        .inject({}) do |breaks, (date, start_time, end_time)|
          breaks.merge!(Time.zone.parse(date).to_date => { parse_time[start_time] => parse_time[end_time] })
        end
    end
  end

  def on_break?(shipping_method_id)
    return true if external_availability == false

    Time.use_zone(timezone) do
      delivery_breaks
        .today_breaks
        .where('ARRAY[?]::integer[] <@ delivery_breaks.shipping_method_ids', shipping_method_id)
        .any? { |b| Time.zone.parse(b.start_time) <= Time.zone.now && Time.zone.parse(b.end_time) >= Time.zone.now }
    end
  end

  def on_holiday_break?(shipping_method_id)
    return true if external_availability == false

    shipping_method = ShippingMethod.find shipping_method_id

    Time.use_zone(timezone) do
      is_on_holiday = holidays.today_breaks.where('?=ANY(shipping_types)', shipping_method.shipping_type).any?
      is_on_holiday = parent.holidays.today_breaks.where('?=ANY(shipping_types)', shipping_method.shipping_type).any? if !is_on_holiday && parent

      return is_on_holiday
    end
  end

  def on_holiday?
    Time.use_zone(timezone) do
      is_on_holiday = !holidays.today.empty?
      is_on_holiday = !parent.holidays.today.empty? if !is_on_holiday && parent

      return is_on_holiday
    end
  end

  def upcoming_holidays
    Time.use_zone(timezone) do
      holiday_dates = holidays.upcoming.pluck(:date).map { |date| Time.zone.parse(date).to_date }
      holiday_dates += parent.holidays.upcoming.pluck(:date).map { |date| Time.zone.parse(date).to_date } if parent

      return holiday_dates.uniq
    end
  end

  def upcoming_holidays_by_shipping_type(shipping_type)
    Time.use_zone(timezone) do
      holiday_dates = holidays.upcoming_by_shipping_type(shipping_type).pluck(:date).map { |date| Time.zone.parse(date).to_date }
      holiday_dates += parent.holidays.upcoming_by_shipping_type(shipping_type).pluck(:date).map { |date| Time.zone.parse(date).to_date } if parent

      return holiday_dates.uniq
    end
  end

  def update_score
    update(score: order_surveys.complete.last_sixty_days.with_score.average(:score) || 4.0)
  end

  def covers_address?(address)
    return false if address.nil?

    shipping_methods
      .where(active: true)
      .joins(:delivery_zones)
      .merge(DeliveryZone.active.containing(address))
      .any?
  end

  # As of TECH-3992, only way to know if VS will be region
  def vineyard_select?
    region && region.name == 'Vineyard Select'
  end

  # TODO: JM: This could all be done properly with validations. No need to re-invent the wheel.
  def ready_to_activate?
    if braintree_merchant_account_id.blank?
      'Please provide a Braintree merchant ID.'
    elsif address.nil?
      'Please provide an address for the supplier.'
    elsif !address.geocoded?
      'Please provide a geocodable address.'
    elsif address.phone.blank?
      'Please provide phone number for supplier.'
    elsif email.blank?
      'Please enter a contact email for the supplier.'
    elsif employees.empty? && (delegate_supplier_id.nil? && !custom_dashboard?)
      'Please add employees for this supplier.'
    elsif shipping_methods.empty? && delegate_supplier_id.nil?
      'Please add a shipping method for this supplier.'
    elsif delivery_hours.size != 7
      'Please add delivery hours for each day of the week.'
    elsif variants.active.available.empty?
      'Please give this supplier some products before trying to activate.'
    elsif profile.nil?
      'Please define a profile for this supplier.'
    elsif profile.hierarchy_type_ids.blank? || profile.categories.blank?
      SupplierProfileUpdateWorker.perform_async(id)
      'Supplier Profile metadata is missing a background task to update it has started. If the issue continues check if this supplier has valid product ids and categories'
    end
  end

  def toggle_activation(user, reason = nil)
    data_to_update = { active: !active? }
    if active?
      data_to_update['activated_at'] = nil
      data_to_update['deactivated_at'] = Time.now
      data_to_update['deactivated_by_id'] = user.id
      data_to_update['deactivated_reason'] = reason
    else
      data_to_update['activated_at'] = Time.now unless activated_at.present?
      data_to_update['deactivated_at'] = nil
      data_to_update['deactivated_by_id'] = nil
      data_to_update['deactivated_reason'] = nil
    end
    broadcast_event(:activated, user.name, prefix: true) if update(data_to_update)
  end

  def display_name
    self[:display_name].blank? ? name : super
  end

  def automated_confirmation_reminders?
    notification_methods.active.sms.exists? || notification_methods.active.phone.exists?
  end

  def braintree?
    braintree_merchant_account_id.present?
  end

  def trak?
    trak_id.present? || onfleet_organization.present?
  end

  def update_employee_states(employee_ids)
    employees.where(id: employee_ids).find_each(&:activate!)
    employees.where.not(id: employee_ids).find_each(&:deactivate!)
  end

  def delete_employees(employee_ids)
    employees.where(id: employee_ids).find_each(&:destroy)
  end

  # Used by v1  dashboard and to generate inventory token. Can probably be removed once Dash v2 is live.
  def hash_name_id
    Digest::MD5.hexdigest("#{name}#{id}")
  end

  # Used by Supplier Dashboard v2 - we cannot use the `hash_name_id` since new-style notifications cause
  # issues on the older dashboard.
  # New style format will be triggered on model updates, in format { channel_id, type, entity_id, entity_type }
  def channel_id
    Digest::MD5.hexdigest("#{id}-#{permalink}")
  end

  def activation_notification_params
    {
      name: name,
      change: active ? 'on' : 'off'
    }
  end

  def create_invoicing_recipient
    InvoicingRecipient.where(
      description: name,
      email: email,
      supplier_id: id
    ).first_or_create
  end

  def start_invoice(business_id, begin_date, end_date)
    # this is going to trigger a lot of hooks in InvoicingLedgerItem
    invoice = create_invoicing_recipient.create_invoice(business_id, begin_date, end_date)
    invoice.begin! if invoice.status == 'new'
    invoice.build! if invoice.status == 'pending' && invoice.line_items.count.zero?

    # TECH-3952 - now we are going to automatically finalize the invoice after it is created
    invoice.finalize! if invoice.status == 'built'
    # TECH-7326 - void empty invoice
    invoice.void! if invoice.line_items.none?

    invoice
  end

  def feature?(feature)
    if feature.is_a? String
      feature_items.try(:include?, FeatureItem.find_by(feature: feature))
    else
      feature_items.try(:include?, feature)
    end
  end

  def shipping_tax_rates
    TaxRate.for_state_and_zipcode(address.state_id, address.zip_code).shipping
  end

  def get_child_supplier_ids
    child_suppliers.map(&:id)
  end

  # we try to get the log from the supplier then from the parent
  def get_supplier_logo
    return supplier_logos&.first if supplier_logos.present?
    return parent.supplier_logos.first if parent.present? && parent.supplier_logos.present?

    nil
  end

  def current_break
    supplier_breaks.upcoming.first
  end

  def show_dsp_flipper
    feature?('Delivery Service Provider Flipper')
  end

  def supplier_ship_states_by_category_id_and_level(ship_category_id, ship_level)
    @supplier_ship_states_by_category_id_and_level ||= supplier_ship_states.index_by { |supplier_ship_state| [supplier_ship_state.ship_category_id, supplier_ship_state.ship_level] }

    @supplier_ship_states_by_category_id_and_level[[ship_category_id, ship_level]]
  end

  def eligible_for_longer_breaks?
    delivery_zones.where(active: true).any? || (delegate&.delivery_zones&.where(active: true)&.any? || false)
  end

  def delegating?
    delegate.present?
  end

  def merchandise?
    supplier_type&.name == 'Merchandise'
  end

  def ship_station_dashboard?
    dashboard_type == Supplier::DashboardType::SHIP_STATION
  end

  private

  def after_save_actions
    active? ? activate_shipping_methods : deactivate_shipping_methods
    # Removing this for performance reasons. I will keep this refreshing only once a day.
    # CoverageZipcodesRefreshWorker.perform_async

    # Temporarily removing this to avoid errors on the migrations: || engraving_changed?
    update_variants if display_name_changed? || engraving_changed?
  end

  def create_supplier_product_order_limits_on_activating_presale_eligibility
    return unless presale_eligible_previously_changed?
    return unless presale_eligible

    PreSale.find_each do |pre_sale|
      new_limit = pre_sale.product_order_limit.supplier_product_order_limits.find_or_initialize_by(supplier_id: id)
      new_limit.order_limit = -1
      new_limit.save
    end
  end

  def destroy_supplier_product_order_limits_on_deactivating_presale_eligibility
    return unless presale_eligible_previously_changed?
    return if presale_eligible

    PreSale.find_each do |pre_sale|
      limit = pre_sale.product_order_limit.supplier_product_order_limits.find_by(supplier_id: id)

      next if limit.nil?

      limit.destroy
    end
  end

  def ensure_no_loop_on_delegate_invoice_suppliers
    return if delegate_invoice_supplier_id.nil?

    errors.add(:reason, "can't delegate invoice to Supplier who delegates invoices to this Supplier.") if delegate_invoice_suppliers.pluck(:id).include?(delegate_invoice_supplier_id)
  end

  def create_city_in_region!
    city = address&.city
    region.cities.create({ name: city, visible: true }) if city && region && !region.cities.exists?(name: city)
  end

  def update_variants
    # Temporarily removing this to avoid errors on the migrations:
    if engraving_changed?
      variants.update_all(options_type: engraving? ? Variant.options_types[:engraving] : nil)
    end
    variants.each(&:reindex_async)
  end

  def deactivate_shipping_methods
    return if active?

    shipping_methods.active.update_all(active: false)
  end

  def activate_shipping_methods
    return unless active?

    shipping_method_to_update = shipping_methods.joins(:delivery_zones)
                                                .where(active: false, delivery_zones: { active: true })

    shipping_method_to_update.update_all(active: true)
  end
end
