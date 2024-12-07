# == Schema Information
#
# Table name: shipments
#
#  id                     :integer          not null, primary key
#  order_id               :integer
#  shipping_method_id     :integer          not null
#  number                 :string
#  state                  :string(255)      default("pending"), not null
#  created_at             :datetime
#  updated_at             :datetime
#  supplier_id            :integer
#  confirmed_at           :datetime
#  canceled_at            :datetime
#  delivery_estimate_id   :integer
#  delivery_fee           :float
#  out_of_hours           :boolean          default(FALSE), not null
#  trak_id                :string(255)
#  delivered_at           :datetime
#  scheduled_for          :datetime
#  late                   :boolean          default(FALSE), not null
#  braintree              :boolean          default(TRUE), not null
#  uuid                   :uuid             not null
#  external_order_id      :string
#  use_delivery_service   :boolean
#  delivery_service_order :jsonb
#  external_shipment_id   :string
#  customer_placement     :integer          default("standard")
#  invoice_status         :integer          default("pending")
#  cancellation_reason_id :integer
#  cancellation_notes     :text
#  delivery_service_id    :integer
#  liquidcommerce         :boolean          default(FALSE), not null
#
# Indexes
#
#  index_shipments_on_canceled_at               (canceled_at)
#  index_shipments_on_external_shipment_id      (external_shipment_id)
#  index_shipments_on_number                    (number)
#  index_shipments_on_order_id                  (order_id)
#  index_shipments_on_order_id_and_supplier_id  (order_id,supplier_id)
#  index_shipments_on_shipping_method_id        (shipping_method_id)
#  index_shipments_on_state                     (state)
#  index_shipments_on_supplier_id               (supplier_id)
#  index_shipments_on_uuid                      (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (cancellation_reason_id => order_adjustment_reasons.id)
#

class Shipment < ActiveRecord::Base
  include Statesman::Adapters::ActiveRecordQueries
  include MachineAdapter
  include Shipment::SegmentSerializer
  include Iterable::Storefront::Serializers::ShipmentSerializer

  # TODO: JM: This is not the way to do this. Should use the presenter pattern.
  # Change Shipment::Decorator to a class inheriting from SimpleDelegator and
  # present the instance to the API. Removing a bunch or weight from shipment.
  include Shipment::Decorator

  acts_as_taggable

  belongs_to :delivery_estimate
  belongs_to :order, touch: true, inverse_of: :shipments
  belongs_to :shipping_method, with_deleted: true
  belongs_to :supplier

  has_many :adjustment_charges, through: :order_adjustments, source: :charge
  has_many :applied_deals
  has_many :chargeables
  has_many :charges, through: :chargeables
  has_many :comments, as: :commentable
  has_many :customer_refunds, through: :charges
  has_many :initial_charges, through: :shipment_charges, source: :charge
  has_many :order_adjustments
  has_many :order_items, inverse_of: :shipment, autosave: true
  has_many :shipment_charges
  has_many :substitutions, -> { order('substitutions.created_at DESC') }
  has_many :sibling_shipments, ->(instance) { where.not(id: instance.id) }, through: :order, source: :shipments
  has_many :shipment_supplier_extras
  has_many :packages, dependent: :destroy
  has_many :custom_tag_shipments, dependent: :destroy
  has_many :custom_tags, through: :custom_tag_shipments
  has_many :tracking_updates, dependent: :destroy

  has_one :address, through: :order, source: :ship_address
  has_one :gift_detail, through: :order
  has_one :last_shipment_charge, -> { order(created_at: :desc) }, class_name: 'ShipmentCharge'
  has_one :initial_charge, through: :last_shipment_charge, source: :charge
  has_one :metadata, class_name: 'ShipmentMetadata'
  has_one :pickup_detail, through: :order
  has_one :region, through: :supplier
  has_one :shipment_amount, dependent: :destroy, inverse_of: :shipment
  has_one :shipping_state, through: :address, source: :state
  has_one :supplier_address, through: :supplier, source: :address
  has_one :tracking_detail
  has_one :user, through: :order, inverse_of: :shipments

  enum customer_placement: { standard: 0, pre_sale: 1, back_order: 2 }, _prefix: true
  enum invoice_status: { pending: 0, invoiced: 1, error: 2 }

  delegate :coupon_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :deals_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :discounts_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :minibar_funded_discounts, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :supplier_funded_discounts, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :shipping_charges, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :shoprunner_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :sub_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :sub_total_with_engraving, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :taxed_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :tax_discounting_bottle_fee, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :sales_tax, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :shipping_tax, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :order_items_tax, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :bottle_deposits, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :tip_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :gift_card_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :additional_tax_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :bag_fee, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :total_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :receipt_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :total_amount_with_engraving, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :invoice_total_amount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :retail_delivery_fee, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :membership_discount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :fulfillment_fee, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :shipping_fee_discounts_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :delivery_fee_discounts_total, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :membership_shipping_discount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'
  delegate :membership_delivery_discount, to: :shipment_amount, allow_nil: true, prefix: 'shipment'

  delegate :potential_membership_shipping_savings, to: :shipping_fee_service
  delegate :potential_membership_on_demand_savings, to: :shipping_fee_service

  delegate :delivered_at, to: :metadata, allow_nil: true, prefix: true
  delegate :driver_id, to: :metadata, allow_nil: true, prefix: true
  delegate :driver, to: :metadata, allow_nil: true, prefix: true
  delegate :signed_by_name, to: :metadata, allow_nil: true, prefix: true
  delegate :delivery_notes, to: :order, allow_nil: true, prefix: true
  delegate :gift?, to: :order, allow_nil: true
  delegate :number, to: :order, allow_nil: true, prefix: true
  delegate :tax_time, to: :order, allow_nil: true
  delegate :name, to: :supplier, allow_nil: true, prefix: true
  delegate :timezone, to: :supplier, prefix: true
  delegate :name, to: :user, allow_nil: true, prefix: true
  delegate :shipping_type, to: :shipping_method, allow_nil: true
  delegate :digital?, to: :shipping_method, allow_nil: true
  delegate :suspected_fraud?, to: :order, allow_nil: true
  delegate :show_dsp_flipper, to: :supplier

  delegate :tracking_number_url, to: :tracking_detail, allow_nil: true
  delegate :dashboard_type, to: :effective_supplier

  after_save :reindex_async
  after_commit :send_update_event

  accepts_nested_attributes_for :order_items, allow_destroy: true
  accepts_nested_attributes_for :applied_deals, allow_destroy: true

  validates :order, presence: true
  validates :shipping_method, presence: true
  validates :customer_placement, inclusion: { in: customer_placements.keys }

  SCHEDULING_BUFFER = 3 # hours
  AGE_IN_DAYS_TO_FIRE_AGING_EVENTS = [4, 7, 11].freeze

  #------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------
  scope :paid, -> { where("shipments.state not in ('pending', 'test', 'canceled')") }
  scope :pending, -> { in_state('pending') }
  scope :not_paid, -> { in_state(%w[back_order pre_sale pending]) }
  scope :ready_to_ship, -> { in_state(%w[ready_to_ship paid]) }
  scope :confirmed, -> { in_state('confirmed') }
  scope :canceled, -> { in_state('canceled') }
  scope :scheduled, -> { in_state('scheduled') }
  # where('scheduled_for > now()') but correctly names the table for joins. This is a hint that :today_supplier
  # could be significantly improved.
  scope :future, -> { where arel_table[:scheduled_for].gt(Arel::Nodes::NamedFunction.new('now', [])) }
  scope :on_demand, -> { joins(:shipping_method).merge(ShippingMethod.on_demand) }
  scope :shipped, -> { joins(:shipping_method).merge(ShippingMethod.shipped) }
  scope :digital, -> { joins(:shipping_method).merge(ShippingMethod.digital) }
  scope :engraving, -> { joins(:shipment_amount).where('engraving_fee > 0') }
  # TODO: Put this in ElasticSearch!
  scope :today_supplier, lambda { |timezone|
    joins(:order)
      .where('shipments.state NOT IN (?)', ['pending'])
      .where('orders.state IN (?)', Order::FINISHED_STATES)
      .where(
        '(shipments.state = :unconfirmed_state OR (shipments.confirmed_at > :start_date AND shipments.confirmed_at <= :end_date)) OR'\
        '(shipments.created_at > :start_date AND shipments.state != :scheduled_state) OR'\
        '(shipments.state = :exception_state) OR'\
        '(shipments.scheduled_for > :start_date AND shipments.scheduled_for <= :scheduling_cutoff_date) OR'\
        '(shipments.state = :canceled_state AND shipments.canceled_at > :start_date)',
        unconfirmed_state: 'ready_to_ship',
        scheduled_state: 'scheduled',
        canceled_state: 'canceled',
        exception_state: 'exception',
        start_date: Time.zone.now.in_time_zone(timezone).beginning_of_day,
        end_date: Time.zone.now.in_time_zone(timezone).end_of_day,
        scheduling_cutoff_date: Time.zone.now.in_time_zone(timezone) + Shipment::SCHEDULING_BUFFER.hours
      )
  }
  scope :for_orders_with_psg, lambda { |psg_id|
    sub_query = Shipment.select(:order_id).with_product_grouping(psg_id).group(:order_id).order(:order_id).to_sql
    where(%["shipments"."order_id" IN (#{sub_query})])
  }

  scope :with_product_grouping, lambda { |psg_id|
    joins(order_items: { variant: [:product] })
      .merge(Product.where(product_grouping_id: psg_id))
      .merge(Shipment.paid)
  }

  scope :first_for_order, ->(order_id) { where(order_id: order_id).order(:id).limit(1) }

  #-----------------------------------
  # SearchKick
  #-----------------------------------

  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             searchable: %i[company_name email first_name gift_recipient last_name number street_address shipping_type product_name custom_tag product_id brand_id storefront_name],
             filterable: %i[completed_at state vip gift supplier_id order_state scheduled_for shipping_type customer_placement created_at],
             text_middle: %i[street_address product_name custom_tag],
             word_start: %i[gift_recipient first_name last_name company_name storefront_name],
             word_middle: [:number],
             batch_size: 200,
             routing: true

  scope :search_import, -> { includes(:user, order: [:ship_address], shipping_method: [], last_shipment_transition: []) }

  # Liquid Commerce attributes
  attr_accessor :liquid,
                :liquidcommerce_fulfillment_total,
                :liquidcommerce_tax_total,
                :liquidcommerce_total,
                :liquidcommerce_subtotal,
                :liquidcommerce_product_tax,
                :liquidcommerce_engraving,
                :liquidcommerce_engraving_discounts,
                :liquidcommerce_engraving_after_discounts,
                :liquidcommerce_fulfillment_fee,
                :liquidcommerce_delivery_fee,
                :liquidcommerce_shipping_tax,
                :liquidcommerce_bag_fee,
                :liquidcommerce_retail_delivery_fee,
                :liquidcommerce_tip_amount,
                :liquidcommerce_bottle_deposits,
                :liquidcommerce_gift_card_amount,
                :liquidcommerce_coupon_amount,
                :liquidcommerce_delivery_fee_discounts,
                :liquidcommerce_shipping_fee_discounts

  def liquidcommerce_tip_share
    return @liquidcommerce_tip_amount if defined?(@liquidcommerce_tip_amount) && @liquidcommerce_tip_amount.present?
    return shipment_tip_amount if shipment_tip_amount.present? && shipment_tip_amount.positive?

    # Tip Share - tip amount assigned to this shipment
    return 0.0 unless shipping_method.present? && shipping_method.allows_tipping

    ValueSplitter.new(order.tip_amount).split(order.eligible_total_for_tipping, sub_total)
  end

  def should_index?
    supplier && order && !pending?
  end

  def reindex_async
    ShipmentReindexWorker.perform_async(id)
  end

  def search_routing
    supplier_id
  end

  def completed_at
    order.completed_at || order.created_at
  end

  # TODO: TIMEZONES! - we should convert to supplier timezone (should we?) and iso8601
  def search_data
    {
      company_name: address&.company, # String, :word_start
      completed_at: completed_at, # Date
      completed_at_int: completed_at.to_i, # Integer NOTE: necessary for date filtering to not truncate time information
      corporate: user.corporate?, # Boolean
      email: user.email, # String
      first_name: user.first_name, # String, :word_start
      gift: gift?, # Boolean
      gift_recipient: gift_detail&.recipient_name, # String, :word_start
      last_name: user.last_name, # String, :word_start
      number: order.number, # String, :word_middle
      order_state: order.state, # String, categorical
      scheduled_for: scheduled_for, # Date
      shipping_type: shipping_method&.shipping_type, # String, categorical
      state: state, # String, categorical
      street_address: address&.address1, # String, :text_middle
      supplier_id: supplier_id, # String, categorical
      vip: user.vip?, # Boolean
      customer_placement: customer_placement, # Integer
      product_name: order_items.map(&:product_trait_name).join(', '), # String, :text_middle
      custom_tag: custom_tags.pluck(:name).join(', '), # String, :text_middle
      product_id: order_items.map(&:product_id).compact,
      brand_id: order_items.map(&:brand_id).compact,
      age_in_days_and_hours: age_in_days_and_hours,
      created_at: created_at.to_date,
      storefront_name: order.storefront.name # String, :word_start
    }
  end

  #-----------------------------------
  # State Machine
  #-----------------------------------
  has_many :shipment_transitions, autosave: false
  has_one :last_shipment_transition, -> { where(most_recent: true) }, class_name: 'ShipmentTransition'

  statesman_machine machine_class: ShipmentStateMachine, transition_class: ShipmentTransition

  #-----------------------------------
  # Class methods
  #-----------------------------------
  def self.find_from_delivery_id(delivery_id, dsp_name = nil)
    shipment = Shipment.find_by id: delivery_id

    if shipment && shipment.delivery_service_order.present?
      Shipment.find(delivery_id)
    elsif dsp_name
      order = Order.find_by(number: delivery_id)
      if order.blank?
        Rails.logger.error "Webhook error: Couldn't find order with number #{delivery_id} (DSP: #{dsp_name})"
        return
      end

      order.shipments.detect do |shpmnt|
        shpmnt.delivery_service&.name == dsp_name
      end
    end
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------
  def first_for_order?
    Shipment.first_for_order(order_id).pluck(:id).one? { |shipment_id| shipment_id == id }
  end

  def en_route_at
    state_machine.history.find_by(to_state: :en_route)&.created_at
  end

  def previous_state
    state_machine.history.where(most_recent: false).order(created_at: :asc)&.last&.to_state
  end

  def notify_deals_shipment_paid
    if applied_deals.any?
      attributes = { shipment_id: id, order_id: order_id }
      Deals::DealGateway::NotifyShipmentPaid.new(attributes, applied_deals.pluck(:reservation_id)).call
    end
  end

  def can_determine_lateness?
    return false if scheduled_for

    shipping_method && delivery_estimate && delivery_estimate.can_calculate_lateness?
  end

  def determined_late?
    (can_determine_lateness? ? delivery_estimate.maximum > shipping_method.maximum_delivery_expectation : false) ||
      (order ? order.tags.exists?(name: 'late_delivery') : false) ||
      order_adjustments.any? { |oa| oa.reason.reporting_type == 'late' } ||
      !shipping_method.delivery_expectation_exceptions.active.empty?
  end

  delegate :pickup?, to: :shipping_method, allow_nil: true
  delegate :on_demand?, to: :shipping_method, allow_nil: true
  delegate :shipped?, to: :shipping_method, allow_nil: true

  def process_late_shipment
    return nil unless determined_late?

    update(late: true)
    order_adjustments.create(supplier: supplier,
                             financial: false,
                             reason: OrderAdjustmentReason.find_by(name: 'Late Delivery'),
                             description: 'Confirmed as Late',
                             user: User.first,
                             amount: 0,
                             braintree: true,
                             credit: false,
                             order: order)
    supplier.add_strike

    broadcast(:shipment_late, self)
  end

  # TODO: Consider renaming to OnFleet and/or abstracting out this and other
  # delivery methods such as UberRUSH
  def trak?
    trak_id.present?
  end

  def adjustable?
    # TODO: Make this track braintree status - are we still able to refund?
    initial_charge.present?
  end

  def refunded?
    initial_charge && (initial_charge.voided? || initial_charge.refunded?)
  end

  def refund!
    charges.each { |charge| charge.cancel! if charge.can_be_cancelled? }
    refund_taxes_and_fees!
  end

  def refund_taxes_and_fees!(amount = nil)
    minibar_charge = order.minibar_charge
    amount = total_minibar_charge if amount.nil?

    if amount.positive? && minibar_charge
      minibar_charge.refund!(amount)
      comments.create({ note: format('Refunded customer $%s for taxes and fees.', amount.to_s),
                        posted_as: :minibar })
    end
  end

  def recipient_id
    supplier.get_braintree_merchant_account_id
  end

  def item_count
    order_items.load_target.sum(&:quantity)
  end

  def case_eligible_item_count
    order_items.load_target.sum { |item| item.case_eligible? ? item.quantity : 0 }
  end

  def case_eligible_item_total
    order_items.load_target.sum { |item| item.case_eligible? ? item.total : 0.0 }.to_d.round_at(2)
  end

  def two_for_one_eligible(deal)
    number_of_eligible_items = 0
    order_items.load_target.each do |item|
      # Check if order item can be consider as candidate for TwoForOneDiscount
      # 1. Item must have two_for_one value set, and it must be the same as deal amount
      # 2. Item quantity can't be lower than deal's minimum units required
      number_of_eligible_items += 1 if !item.two_for_one.nil? && item.two_for_one == deal.amount && (item.quantity >= deal.minimum_units.to_i)
    end
    number_of_eligible_items.positive?
  end

  def non_alcohol_item_count
    order_items.load_target.sum { |item| item.alcohol? ? 0 : item.quantity }
  end

  def non_alcohol_item_total
    order_items.load_target.sum { |item| item.alcohol? ? 0.0 : item.total }.to_d.round_at(2)
  end

  def contains_alcohol?
    order_items.load_target.any?(&:alcohol?)
  end

  def add_order_item(order_item, user_id)
    adjustment_description = "Order Item added: #{order_item.description}"
    reason = OrderAdjustmentReason.find_by(name: 'Order Change - Item Added to Order')

    @total_before_supplier = total_supplier_charge
    @total_before_minibar = total_minibar_charge

    order_item.save

    order_items.reload

    change_order_items(order_item, user_id, reason.id, adjustment_description)
  end

  def remove_order_item(order_item, user_id, quantity = nil)
    is_delete = false
    @total_before_supplier = total_supplier_charge
    @total_before_minibar = total_minibar_charge

    unless quantity.nil?
      order_item.quantity -= quantity
      order_item.save
    end
    if order_item.quantity < 1 || quantity.nil?
      order_items.delete(order_item)
      is_delete = true
    end

    adjustment_description = if is_delete
                               "Order Item removed: #{order_item.description}"
                             else
                               "#{quantity} items of the order Item: #{order_item.description} were removed"
                             end

    reason = OrderAdjustmentReason.find_by(name: 'Order Change - Item Removed from Order (Not OOS, Customer Requested)')

    change_order_items(order_item, user_id, reason.id, adjustment_description)
  end

  def change_order_items(_order_item, user_id, reason_id, adjustment_description)
    recalculate_amounts
    recalculate_order_amounts

    new_total_supplier = total_supplier_charge
    new_total_minibar = total_minibar_charge

    @difference_supplier = @total_before_supplier - new_total_supplier
    @credit_supplier = @difference_supplier.positive?
    @financial_supplier = @difference_supplier != 0

    order_adjustment_params = { user_id: user_id,
                                reason_id: reason_id,
                                description: format('Description: %s', adjustment_description),
                                substitution_id: id,
                                credit: @credit_supplier,
                                financial: @financial_supplier,
                                amount: @difference_supplier.abs,
                                braintree: @financial_supplier,
                                processed: false }
    create_service = OrderAdjustmentCreationService.new(self, order_adjustment_params)
    create_service.process_now!

    @difference_minibar = @total_before_minibar - new_total_minibar
    if @difference_minibar != 0
      @credit_minibar = @difference_minibar.positive?
      @financial_minibar = @difference_minibar != 0
      order_adjustment_params = { user_id: user_id,
                                  reason_id: reason_id,
                                  description: format('Taxes and Fees adjustment: %s', adjustment_description),
                                  substitution_id: id,
                                  credit: @credit_minibar,
                                  financial: @financial_minibar,
                                  amount: @difference_minibar.abs,
                                  braintree: @financial_minibar,
                                  processed: false }
      create_service = OrderAdjustmentCreationService.new(self, order_adjustment_params, true)
      create_service.process_now!
    end

    comments.create({ note: format('%s Order adjustment is coming.', adjustment_description),
                      created_by: user_id,
                      posted_as: :minibar })

    broadcast_event(:shipment_order_items_changed)
  end

  def recalculate_amounts
    order.coupon_balance_adjustments.destroy_all
    recalculate_and_apply_taxes
    order.save_order_amount(skip_coupon_creation: false)
    order.order_amount.create_balance_adjustment
  end

  def recalculate_order_amounts
    order.coupon_balance_adjustments.destroy_all
    order.recalculate_and_apply_taxes
    recalculate_and_apply_taxes
    order.save_order_amount
    order.order_amount.create_balance_adjustment
  end

  def set_delivery_fee
    self.delivery_fee = estimate_delivery_fee
  end

  def update_delivery_fee
    return if liquid || liquidcommerce # Skip for liquid orders

    set_delivery_fee
    save
  end

  def set_scheduled_reminders
    return unless scheduled_for

    Time.use_zone(supplier.timezone) do
      current_supplier_time = Time.current

      # Currently setting up reminder time to be 3 hours before the scheduled time. We may want
      # to be smarter here later on, maybe start of day.
      reminder_time = Shipment::SCHEDULING_BUFFER.hours.until(scheduled_for)

      # Handle the case for same-day scheduling when the default reminder time may be before
      # the current time.
      reminder_time = current_supplier_time if reminder_time < current_supplier_time

      # Supplier Reminder
      Shipment::ScheduledReminderWorker.perform_at(reminder_time, id)

      # Reminder for Minibar CS if not confirmed
      remind_cs_at = scheduled_for + shipping_method.create_unconfirmed_asana_task_time.minutes
      Shipment::WithoutConfirmationWorker.perform_at(remind_cs_at, id)

      # Generate automatic supplier comment
      confirmation_check_at = scheduled_for + shipping_method.automatic_supplier_comment_time.minutes
      ShipmentUnconfirmedCommentWorker.perform_at(confirmation_check_at, id, 'scheduled')
    end

    # Reminder for asana notification if no driver after some time
    DeliveryServiceReminderWorker.perform_at(30.minutes.from_now, id, true, 30) if supplier.delivery_service.present?
  end

  # Create Asana Task if order is found unconfirmed 20 mins into delivery window
  def set_asana_scheduled_reminders(from_state)
    return unless scheduled_for

    Time.use_zone(supplier.timezone) do
      confirmation_check_at = scheduled_for + shipping_method.create_unconfirmed_asana_task_time.minutes
      Shipment::WithoutConfirmationWorker.perform_at(confirmation_check_at, id, from_state)

      # Generate automatic supplier comment
      confirmation_check_at = scheduled_for + shipping_method.automatic_supplier_comment_time.minutes
      ShipmentUnconfirmedCommentWorker.perform_at(confirmation_check_at, id, from_state)
    end
  end

  # Create Supplier Notification and Supplier Comment if no tracking number 72 hours after order is created
  def set_no_tracking_number_reminders
    return if shipped_with_tracking_number?

    Time.use_zone(supplier.timezone) do
      no_tracking_number_reminder_time = Time.now + 3.days
      Shipment::WithoutTrackingNumberWorker.perform_at(no_tracking_number_reminder_time, id)
    end
  end

  def set_out_of_hours
    self.out_of_hours = true if shipping_method.closed?(order&.completed_at || updated_at)
  end

  def send_confirmation_reminder
    return unless paid?
    return unless supplier.automated_confirmation_reminders?

    supplier.notification_methods.active.find_each do |notification_method|
      next unless notification_method.phone? || notification_method.sms?

      notification_method.send_reminder(self)
    end
  end

  def add_unconfirmed_comment
    return if canceled? && order&.canceled?
    return unless paid? || scheduled?
    return unless comments.empty?
    return unless substitutions.empty?
    return if exception?

    comments.create(
      note: 'Please review this order and confirm if there are no issues.',
      user_id: order.user_id,
      posted_as: :minibar
    )
  end

  def add_no_tracking_number_comment
    return if shipped_with_tracking_number? || canceled? || order&.canceled?

    comments.create(
      note: 'Please provide tracking information for this shipping order.',
      user_id: order.user_id,
      posted_as: :minibar
    )
  end

  def send_tracking_number_reminder
    return if shipped_with_tracking_number?
    return unless supplier.automated_confirmation_reminders?

    supplier.notification_methods.active.find_each do |notification_method|
      next unless notification_method.phone? || notification_method.sms?

      notification_method.send_reminder(self, 'tracking')
    end
  end

  def check_order_confirmation
    return unless paid?
    return if scheduled_for

    broadcast_event(:unconfirmed, prefix: true)
    supplier.add_strike(1)
    order.touch
  end

  def late_confirmation?
    !confirmed? && created_at < Time.zone.now - shipping_method.confirmation_time.minutes
  end

  def supplier_invoice_uuid
    # TODO: Eventually we'll want to get rid of the number column and regenerate
    # or rename older invoices.
    "shipment_invoice_#{Rails.env}_#{number || uuid}"
  end

  # TODO: Would like to think of a better way to do this - the product/product type
  #       should be responsible for additonal_notes or something like that.
  def has_white_or_sparkling_wine?
    return false if order_items.any? { |o| o.variant.blank? } # if any of the order items have no variants, everything else should be set long before

    order_items.any? { |o| o.variant.product_type&.is_white_wine? || o.variant.product_type&.is_sparkling_wine? }
  end

  def notify_supplier_dash
    in_today = Shipment.today_supplier(supplier.timezone).find_by(id: id).present?
    ShipmentDashboardNotificationWorker.perform_async(id) if in_today && order.consider_paid?
    true
  end

  def sync_liquidcommerce_attributes!(fulfillment_data)
    # details = fulfillment_data[:details] || {}
    # taxes = details[:taxes] || {}
    # discounts = details[:discounts] || {}
    #
    # # Calculate core values
    # base_shipping = fulfillment_data[:shipping].to_f / 100.0
    # base_delivery = fulfillment_data[:delivery].to_f / 100.0
    # total_shipping = base_shipping + base_delivery
    # product_tax = (taxes[:products] || 0).to_f / 100.0
    # shipping_tax = (taxes[:shipping].to_i + taxes[:delivery].to_i + taxes[:retailDelivery].to_i).to_f / 100.0
    #
    # # Get the actual discount amount from the fulfillment total
    # total_discount = (fulfillment_data[:discounts] || 0).to_f / 100.0
    #
    # # Important: Don't treat discount as shipping discount if it's a regular coupon
    # shipping_discount = (discounts[:shipping] || 0).to_f / 100.0
    # delivery_discount = (discounts[:delivery] || 0).to_f / 100.0

    liquidcommerce_values = LiquidCommerceShipments::ShipmentAttributes.new(
      self.order,
      self
    ).build_amount_attributes(fulfillment_data)

    liquidcommerce_values.each do |key, value|
      instance_variable_set("@liquidcommerce_#{key}", value)
    end

    # FORCE THE VALUES DIRECTLY
    @delivery_fee = (fulfillment_data[:delivery] || 0).to_f / 100.0
    @shipping_fee = (fulfillment_data[:shipping] || 0).to_f / 100.0
    @fulfillment_fee = liquidcommerce_values.fetch(:fulfillment_fee, 0)
    @shipping_tax = liquidcommerce_values.fetch(:shipping_tax, 0)

    # Zero out instance vars
    @liquidcommerce_delivery_fee = (fulfillment_data[:delivery] || 0).to_f / 100.0
    @liquidcommerce_shipping_fee = (fulfillment_data[:shipping] || 0).to_f / 100.0
    @liquidcommerce_fulfillment_fee = liquidcommerce_values.fetch(:fulfillment_fee, 0)
    @liquidcommerce_shipping_tax = liquidcommerce_values.fetch(:shipping_tax, 0)

    # Other values from liquidcommerce
    @liquidcommerce_subtotal = (fulfillment_data[:subtotal] || 0).to_f / 100.0
    @liquidcommerce_tax_total = (fulfillment_data[:tax] || 0).to_f / 100.0
    @liquidcommerce_total = (fulfillment_data[:total] || 0).to_f / 100.0

    self.liquidcommerce = true

    true
  rescue => e
    Rails.logger.error("[LIQUID_COMMERCE] Error syncing attributes for shipment: #{e.message}")
    raise
  end

  def isOnDemand?(fulfillment)
    fulfillment[:type] == 'onDemand'
  end

  def calculate_ship_delivery_tax(taxes)
    (
      taxes[:shipping].to_i +
        taxes[:delivery].to_i +
        taxes[:retailDelivery].to_i
    ).to_f / 100.0
  end

  def calculate_ship_delivery_fee(fulfillment_data)
    (
      fulfillment_data[:shipping].to_i +
        fulfillment_data[:delivery].to_i
    ).to_f / 100.0
  end

  # In Shipment model
  def shipping_fee_after_discounts
    return 0.0 if order.free_shipping_or_delivery_coupon?

    shipping_fee - shipping_fee_discounts_total
  end

  def calculate_ship_delivery_discounts(discounts)
    (
      discounts[:shipping].to_i +
        discounts[:delivery].to_i
    ).to_f / 100.0
  end

  def calculate_engraving_after_discounts(fulfillment_data, discounts)
    (
      fulfillment_data[:engraving].to_i -
        discounts[:engraving].to_i
    ).to_f / 100.0
  end

  def log_debug(message)
    Rails.logger.debug("[LIQUID_COMMERCE] #{message}")
  end

  def save_shipment_amount
    if liquidcommerce
      save_liquidcommerce_shipment_amount
    else
      original_save_shipment_amount
    end
  end

  def original_save_shipment_amount
    amount_attributes = {
      sub_total: sub_total,
      tip_amount: tip_share,
      shipping_charges: delivery_fee,
      shipping_fee_discounts_total: shipping_fee_service.shipping_discount,
      delivery_fee_discounts_total: shipping_fee_service.delivery_discount,
      fulfillment_fee: shipping_fee_service.fulfillment_fee,
      taxed_amount: tax_total_with_bottle_deposits_and_bag_fees + retail_delivery_fee,
      coupon_amount: coupon_amount,
      deals_total: deals_amount,
      discounts_total: discounts_total,
      shoprunner_total: shoprunner_amount,
      taxed_total: total,
      total_before_discounts: total_before_discounts,
      total_before_coupon_applied: total_before_deals,
      order_items_total: sub_total,
      shipping_tax: shipping_tax,
      order_items_tax: order_items_tax,
      bottle_deposits: bottle_deposit_fees,
      bag_fee: bag_fee,
      engraving_fee: engraving_fee_without_discounts,
      engraving_fee_discounts: engraving_fee_discounts,
      engraving_fee_after_discounts: engraving_fee,
      line_item_id: shipment_amount&.line_item_id,
      gift_card_amount: gift_card_amount,
      retail_delivery_fee: retail_delivery_fee,
      membership_discount: membership_discount,
      membership_shipping_discount: shipping_fee_service.membership_shipping_discount,
      membership_delivery_discount: shipping_fee_service.membership_delivery_discount
    }

    if shipment_amount.present?
      shipment_amount.update(amount_attributes)
    else
      shipment_amount = create_shipment_amount(amount_attributes)
    end

    save

    shipment_amount&.line_item&.refresh
    shipment_amount
  end

  # Enhance save_shipment_amount to respect liquidcommerce values
  alias_method :original_save_shipment_amount, :save_shipment_amount

  def short_recipient_name
    if gift? && gift_detail.recipient_name.present?
      gift_detail.recipient_name
    elsif pickup_detail&.name.present?
      pickup_detail.name
    elsif digital?
      order_items.gift_card.map { |oi| oi.item_options.recipients }.flatten
    elsif address.present?
      address.name
    else
      "#{user.first_name} #{user.last_name}"
    end
  end

  def long_recipient_name
    [short_recipient_name, address&.company].compact.join(' - ')
  end

  def gift_recipient
    gift_detail&.recipient_name
  end

  def recipient_name
    pickup_detail&.name || address&.name || "#{user.first_name} #{user.last_name}"
  end

  def recipient_email
    gift_detail&.recipient_email || user.email
  end

  def recipient_phone
    pickup_detail&.phone || gift_detail&.recipient_phone || address&.phone
  end

  def use_delivery_service?
    # if delivery service is ShipCompliant we still want the supplier to provide the tracking number
    show_dsp_flipper ? use_delivery_service : supplier.delivery_service_id.present? && supplier.delivery_service.name != 'ShipCompliant'
  end

  def delivery_service_order
    self[:delivery_service_order] || order.delivery_service_order
  end

  def delivery_service
    use_delivery_service? || supplier&.delivery_service&.name == 'ShipCompliant' ? supplier.delivery_service : nil
  end

  def tax_exempt?
    return true if digital? # TECH-2881 we might want to know if all digital is tax free

    order.tax_exempt?
  end

  def can_autoconfirm?
    digital? && !unapproved_gift_card_image?
  end

  def needs_gift_card_image_review?
    digital? && unapproved_gift_card_image?
  end

  def unapproved_gift_card_image?
    order_items.gift_card.find { |oi| oi.item_options&.unapproved_gift_card_image? }.present?
  end

  def approve_custom_gift_card_images!
    order_items.gift_card.each do |order_item|
      gc_image = order_item.item_options&.gift_card_image
      gc_image.approve! if gc_image.present?
    end
  end

  def tip_share
    return @tip_amount if @tip_amount.present?
    return shipment_tip_amount if shipment_tip_amount.present? && shipment_tip_amount.positive?

    # Tip Share - tip amount assigned to this shipment
    return 0.0 unless shipping_method.present? && shipping_method.allows_tipping

    ValueSplitter.new(order.tip_amount).split(order.eligible_total_for_tipping, sub_total)
  end

  # Engraving
  def engraving?
    order_items.any?(&:engraving?)
  end

  def engraving_quantity
    order_items = OrderItem.joins(:item_options).where(shipment_id: id, item_options: { type: 'EngravingOptions' })
    # TODO: Add cache? @engraving_quantity ||=
    order_items.sum(Arel.sql('COALESCE(quantity, 1)'))
  end

  def engraving_fee_without_discounts
    # Use ruby to have ability preload :order_items
    order_items.select(&:engraving?).sum(&:engraving_fee)
  end

  def engraving_fee_discounts
    return 0 if order.blank?

    engraving_fee_discount_calculation(order.engraving_discount_percent)
  end

  def engraving_fee_membership_discounts
    return 0 if order.blank?

    percent_discount = order.membership_plan_record&.apply_engraving_percent_off? || 0.0

    engraving_fee_discount_calculation(percent_discount)
  end

  def engraving_fee_discounts_without_membership_discount
    engraving_fee_discounts - engraving_fee_membership_discounts
  end

  def engraving_fee
    engraving_fee_without_discounts - engraving_fee_discounts
  end

  # Fees
  def delivery_fee
    super || set_delivery_fee
  end

  def override_delivery_fee(delivery_fee)
    self.delivery_fee = delivery_fee
    @delivery_fee = delivery_fee
  end

  def override_shipping_fee(shipping_fee)
    @shipping_fee = shipping_fee
  end

  def override_fulfillment_fee(fulfillment_fee)
    @fulfillment_fee = fulfillment_fee
  end

  alias shipping_fee delivery_fee

  def bottle_deposit_fees
    order_items.load_target.sum(&:bottle_fee).to_d.round_at(2)
  end

  def bag_fee
    @bag_fee || shipment_bag_fee || 0.0
  end

  def override_bag_fee(bag_fee)
    @bag_fee = bag_fee
  end

  def retail_delivery_fee
    @retail_delivery_fee || shipment_retail_delivery_fee || 0.0
  end

  def set_retail_delivery_fee(retail_delivery_fee)
    @retail_delivery_fee = retail_delivery_fee || 0.0
  end

  def override_tip_amount(tip_amount)
    @tip_amount = tip_amount
  end

  def bottle_deposits_and_bag_fees
    (bottle_deposit_fees + bag_fee).to_f.round_at(2)
  end

  def fees_total
    (shipping_fee + bottle_deposit_fees + bag_fee + retail_delivery_fee + engraving_fee_without_discounts).to_f.round_at(2)
  end

  def fees_total_without_engraving
    (fees_total - engraving_fee_without_discounts).to_f.round_at(2)
  end

  # Taxes
  def tax_total_with_bottle_deposits_and_bag_fees
    (tax_total + bottle_deposits_and_bag_fees).to_f.round_at(2)
  end

  def order_items_tax
    order_items.load_target.sum(&:tax_charge).to_d.round_at(2)
  end

  def shipping_tax
    @shipping_tax || shipment_shipping_tax || 0.0
  end

  def set_shipping_tax(shipping_tax)
    @shipping_tax = shipping_tax
  end

  def tax_total
    (order_items_tax + shipping_tax).to_f.round_at(2)
  end

  # Discounts
  def deals_amount
    # Deals - automatically applied discounts (deals app)
    Float(applied_deals.load_target.sum(&:value)).round_at(2)
  end

  # TODO: We should think about the case where a coupon is only eligible on a single
  #       shipment (e.g. beer store self funds a special promo). In this case we
  #       should only apply the discount across the shipments belonging to suppliers
  #       for whom the coupon is eligible.
  def coupon_share
    # Coupon Share - discount amount from promo codes and gift cards assigned to this shipment
    Shipment::CouponShare.new(self).call
  end

  def gift_card_amount
    # GiftCard - discount amount from applied gift card
    return 0 if digital?

    order_total =
      order.without_digital_total_before_coupon_applied -
      order.membership_price

    total_before_deals_for_coupon = total_before_deals

    if order.free_shipping_or_delivery_coupon?
      total_before_deals_for_coupon -= delivery_fee + shipping_tax
      order_total -= order.shipping_charges + order.shipping_tax
    end

    ValueSplitter
      .new(order.gift_card_amount_share, limit: total_before_deals_for_coupon)
      .split(order_total, total_before_deals_for_coupon)
  end

  def gift_card_amount_for_tax
    gift_card_amount + free_product_discount + engraving_fee_discounts
  end

  def promo_amount
    # Promo - discount amount from promo codes
    (coupon_share + engraving_fee_discounts_without_membership_discount - gift_card_amount).to_f.round_at(2)
  end

  def coupon_amount
    coupon_share + free_product_discount + engraving_fee_discounts_without_membership_discount
  end

  def shoprunner_amount
    # Shoprunner - discounts shipping fee on eligible orders
    return 0.0 unless shoprunner_eligible?

    estimate_delivery_fee
  end

  def discounts_total
    (deals_amount + coupon_share + shoprunner_amount + free_product_discount).to_d.round_at(2)
  end

  # If order has coupon for free_product, this discount should be applied to cheapest item of given product_id
  # amongs all shipments in order
  def free_product_item
    # we assume there could be only one such coupon per order
    free_product_coupon = order.all_coupons.detect { |c| c.free_product_id.present? }
    return nil if free_product_coupon.nil?

    # if free product quantity condition is not met then no discount
    return nil unless free_product_coupon.contains_free_product_in_required_quantity?(order)

    # selecting cheapest item from all items in whole order, related to free_product_id. If there are items in
    # different shipments with lowest price, then choosing item with smaller shipment_id
    free_item =
      order
      .order_items.joins(:variant)
      .where(variants: { product_id: free_product_coupon.free_product_id })
      .order('order_items.price, order_items.shipment_id')
      .first

    # if free item is found but in other shipment, then no discount
    return nil if free_item.shipment_id != id

    free_item
  end

  def free_product_discount
    free_product_item&.price || 0.0
  end

  def membership_discount
    membership_discount = 0.0
    plan = order.membership_plan_record
    return membership_discount unless plan

    membership_discount += engraving_fee_membership_discounts if plan.apply_engraving_percent_off? && engraving_fee_without_discounts.nonzero?
    membership_discount += shipping_fee_service.membership_shipping_discount
    membership_discount += shipping_fee_service.membership_delivery_discount

    membership_discount
  end

  def cached_free_product_item
    return @cached_free_product_item if defined?(@cached_free_product_item)

    @cached_free_product_item = free_product_item
  end

  def discounts_total_share
    @discounts_total_share ||= (shipment_discounts_total || discounts_total) - (cached_free_product_item&.price || 0.0)
  end

  # Totals
  def sub_total
    Float(order_items.load_target.sum(&:total)).round_at(2)
  end

  def invoicing_sub_total
    sub_total - total_business_remitted_items
  end

  def total_amount
    Float(sub_total + tax_total + bottle_deposits_and_bag_fees + engraving_fee).round_at(2)
  end

  def total_before_discounts
    total = sub_total + tax_total + tip_share
    total += fees_total_without_engraving unless order.free_shipping_or_delivery_coupon?
    total.to_f.round_at(2)
  end

  def total_before_gift_cards
    Float(total_before_discounts + engraving_fee - promo_amount).round_at(2)
  end

  def total_before_deals
    Float(total_before_discounts - deals_amount).round_at(2)
  end

  def total
    total = total_before_discounts
    total -= discounts_total
    total = 0 if total.negative?
    total.round(2)
  end

  # Shipment Charge Amounts
  def total_supplier_charge_without_discounts
    # subtotal + shipping fee (no tax) + tip + bottle deposit fee + bag fee - business_remitted_items
    amount = sub_total + delivery_fee + tip_share + bottle_deposit_fees + bag_fee - total_business_remitted_items
    amount = 0 if amount.negative?
    amount.round(2)
  end

  def total_supplier_charge
    # total_supplier_charge_without_discounts - discounts
    amount = total_supplier_charge_without_discounts - discounts_total

    amount = 0 if amount.negative?
    amount.round(2)
  end

  def total_minibar_charge_without_discounts
    # sales tax + shipping tax + engraving fee + business remitted products + retail_delivery_fee
    amount = order_items_tax + shipping_tax + engraving_fee_without_discounts + total_business_remitted_items + retail_delivery_fee
    amount = 0 if amount.negative?
    amount.round(2)
  end

  def total_business_remitted_items
    order_items.load_target.select { |oi| oi.variant.product_size_grouping.business_remitted? }.sum(&:total).to_f.round(2)
  end

  def total_minibar_charge
    # total_minibar_charge_without_discounts - engraving discount - remaining discounts
    already_discounted_amount = total_supplier_charge_without_discounts - total_supplier_charge
    remaining_discount_amount = [discounts_total - already_discounted_amount, 0].max

    amount = total_minibar_charge_without_discounts - engraving_fee_discounts - remaining_discount_amount
    amount = 0 if amount.negative?
    amount.round(2)
  end

  def calculate_taxes(fallback_address = nil)
    return @tax_calculation if !@tax_calculation.nil? && @tax_calculation.valid?(self, fallback_address)

    @tax_calculation = if order.free_shipping_or_delivery_coupon?
                         # For free shipping coupons, calculate tax but set shipping tax to 0 after
                         tax_calc = Avalara::TaxService.new(self, fallback_address).calculate_tax
                         @shipping_tax = 0.0  # Zero out shipping tax specifically
                         tax_calc
                       else
                         Avalara::TaxService.new(self, fallback_address).calculate_tax
                       end
  end

  def recalculate_and_apply_taxes(fallback_address = nil)
    reload
    update_delivery_fee
    tax_calculation = calculate_taxes(fallback_address)

    @shipping_tax = tax_calculation.get_shipping_tax
    @bag_fee = seven_eleven_bag_fee || tax_calculation.get_bag_fee
    @retail_delivery_fee = tax_calculation.get_retail_delivery_fee

    order_items.each do |oi|
      oi.recalculate_and_apply_taxes
      oi.save
    end

    save_shipment_amount
  end

  def seven_eleven_bag_fee
    return bag_fee if Feature[:seven_eleven_bag_fee].enabled? && supplier.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN

    nil
  end

  def bartender_shipment?
    order_items.all? { |oi| oi.hierarchy_category&.name&.to_s&.downcase == 'book a bartender' }
  end

  def retail_delivery_fee_shipment?
    states = ['CO'] & [order&.ship_address&.state&.abbreviation, order&.ship_address&.state_name, order&.promo_address&.fetch('state')]
    states.any?
  end

  def all_packages_delivered?
    packages.any? && packages.pluck(:state).all? { |state| state == 'delivered' }
  end

  def all_packages_en_route?
    packages.any? && packages.pluck(:state).all? { |state| state == 'en_route' }
  end

  def shipped_with_tracking_number?
    shipped? && (tracking_detail.present? || tracking_detail&.reference.present? || packages.any?)
  end

  def effective_supplier
    supplier.delegate_supplier_id.present? ? Supplier.find(supplier.delegate_supplier_id) : supplier
  end

  def free_delivery?
    order.free_shipping_or_delivery_coupon?
  end

  def engraving_items
    return [] unless engraving?

    order_items.select(&:engraving?)
  end

  def age_in_days
    (Date.current - created_at.to_date).to_i
  end

  def age_in_days_and_hours
    seconds_diff = (created_at - DateTime.current).to_i.abs

    days = seconds_diff / 86_400
    seconds_diff -= days * 86_400
    hours = seconds_diff / 3600

    "#{days.to_s.rjust(2, '0')}d #{hours.to_s.rjust(2, '0')}h"
  end

  def transition_to_previous_state
    return if shipment_transitions.size < 2

    previous_state = shipment_transitions[-2]&.to_state&.to_sym
    transition_to!(previous_state)
  end

  def engraving_chargeable
    chargeables.find { |c| c.description == 'Engraving Fee' }
  end

  def supplier_charges
    charge_ids = Chargeable.where(taxes: [false, nil], shipment_id: id).pluck(:charge_id)
    records = charges.where(id: charge_ids)
    records = records.reject { |c| c.id == engraving_chargeable.charge&.id } if engraving_chargeable.present?
    records
  end

  def can_be_rescheduled?
    return false if dashboard_type == Supplier::DashboardType::SPECS

    !%w[canceled pending].include?(state) && shipping_method.on_demand?
  end

  def pre_sale_eligible_for_supplier_switching?(new_supplier)
    return false unless customer_placement_pre_sale?
    return false unless pre_sale?

    Supplier.eligible_for_pre_sale_shipment(self).exists?(id: new_supplier.id)
  end

  def send_update_event
    # send webhook if shipment is updated
    Webhooks::ShipmentUpdateWebhookWorker.perform_async(id) if Feature['enabled_webhook'].enabled?
  rescue StandardError => e
    Rails.logger.error("Error while checking webhook condition: #{e.message}")
  end

  def liquid_shipment?
    @liquid_shipment ||= order_items.any? { |oi| oi.variant&.liquid_id.present? }
  end

  private

  ##
  # Initializes all liquidcommerce attributes with safe defaults
  # @return [Boolean] true if initialization was performed, false if already initialized
  def init_liquidcommerce_attributes
    @liquidcommerce_initialized = instance_variable_defined?(:@liquidcommerce_initialized)
    return false if @liquidcommerce_initialized

    begin
      # Define attributes map for validation
      attributes = {
        subtotal: 0.0,
        tax_total: 0.0,
        total: 0.0,
        product_tax: 0.0,
        shipping_tax: 0.0,
        delivery_fee: 0.0,
        shipping_fee: 0.0,
        fulfillment_fee: 0.0,
        bag_fee: 0.0,
        engraving: 0.0,
        engraving_discounts: 0.0,
        engraving_after_discounts: 0.0,
        gift_card_amount: 0.0,
        coupon_amount: 0.0,
        retail_delivery_fee: 0.0,
        delivery_fee_discounts: 0.0,
        shipping_fee_discounts: 0.0,
        bottle_deposits: 0.0
      }

      # Set each attribute with validation
      attributes.each do |key, value|
        var_name = "@liquidcommerce_#{key}"
        instance_variable_set(var_name, value)

        # Verify assignment
        actual_value = instance_variable_get(var_name)
        unless actual_value == value
          raise "Failed to initialize #{var_name}. Expected: #{value}, Got: #{actual_value}"
        end
      end

      @liquidcommerce_initialized = true
      Rails.logger.info("[LIQUID_COMMERCE] Successfully initialized attributes")
      true
    rescue => e
      Rails.logger.error("[LIQUID_COMMERCE] Failed to initialize attributes" )
      raise
    end
  end

  ##
  # Retrieves liquidcommerce value with fallback
  # @param attr_name [String] the attribute name without '@liquidcommerce_' prefix
  # @param fallback_method [Proc] the fallback calculation
  # @return [Float] the value to use
  def get_liquidcommerce_value(attr_name, fallback_method)
    var_name = "@liquidcommerce_#{attr_name}"

    begin
      value = instance_variable_get(var_name)

      if !liquidcommerce || !value.present?
        fallback_value = fallback_method.call

        return fallback_value
      end

      value
    rescue => e
      Rails.logger.error("[LIQUID_COMMERCE] Error retrieving value")
      raise
    end
  end

  ##
  # Saves the shipment amount with liquidcommerce values
  # @return [ShipmentAmount] the saved shipment amount
  def save_liquidcommerce_shipment_amount
    Rails.logger.info("[LIQUID_COMMERCE] Starting save with association cache")

    begin
      cached_amount = @association_cache[:shipment_amount]&.target

      if cached_amount.present?
        amount_attributes = {
          # Core amounts
          sub_total: cached_amount.sub_total || get_liquidcommerce_value('subtotal', -> { sub_total }) || sub_total || 0.0,
          taxed_amount: cached_amount.taxed_amount || get_liquidcommerce_value('tax_total', -> { tax_total_with_bottle_deposits_and_bag_fees + retail_delivery_fee }) || tax_total_with_bottle_deposits_and_bag_fees + retail_delivery_fee || 0.0,
          shipping_charges: cached_amount.shipping_charges || get_liquidcommerce_value('delivery_fee', -> { delivery_fee }) || delivery_fee || 0.0,
          fulfillment_fee: cached_amount.fulfillment_fee || get_liquidcommerce_value('fulfillment_fee', -> { shipping_fee_service&.fulfillment_fee }) || shipping_fee_service&.fulfillment_fee || 0.0,
          tip_amount: cached_amount.tip_amount || get_liquidcommerce_value('tip_amount', -> { shipping_fee_service&.tip_amount }) || shipping_fee_service&.tip_amount || 0.0,
          taxed_total: cached_amount.taxed_total || get_liquidcommerce_value('total', -> { total }) || total || 0.0,

          # Order specific amounts
          order_items_total: cached_amount.order_items_total || get_liquidcommerce_value('subtotal', -> { sub_total }) || sub_total || 0.0,
          order_items_tax: cached_amount.order_items_tax || get_liquidcommerce_value('product_tax', -> { order_items_tax }) || order_items_tax || 0.0,

          # Fees and taxes
          shipping_tax: cached_amount.shipping_tax || get_liquidcommerce_value('shipping_tax', -> { shipping_tax }) || shipping_tax || 0.0,
          bottle_deposits: cached_amount.bottle_deposits || get_liquidcommerce_value('bottle_deposits', -> { bottle_deposit_fees }) || bottle_deposit_fees || 0.0,
          bag_fee: cached_amount.bag_fee || get_liquidcommerce_value('bag_fee', -> { bag_fee }) || bag_fee || 0.0,

          # Engraving related
          engraving_fee: cached_amount.engraving_fee || get_liquidcommerce_value('engraving', -> { engraving_fee_without_discounts }) || engraving_fee_without_discounts || 0.0,
          engraving_fee_discounts: cached_amount.engraving_fee_discounts || get_liquidcommerce_value('engraving_discounts', -> { engraving_fee_discounts }) || engraving_fee_discounts || 0.0,
          engraving_fee_after_discounts: cached_amount.engraving_fee_after_discounts || get_liquidcommerce_value('engraving_after_discounts', -> { engraving_fee }) || engraving_fee || 0.0,

          # Discounts and adjustments
          gift_card_amount: cached_amount.gift_card_amount || get_liquidcommerce_value('gift_card_amount', -> { gift_card_amount }) || gift_card_amount || 0.0,
          coupon_amount: cached_amount.coupon_amount || get_liquidcommerce_value('coupon_amount', -> { coupon_amount }) || coupon_amount || 0.0,
          retail_delivery_fee: cached_amount.retail_delivery_fee || get_liquidcommerce_value('retail_delivery_fee', -> { retail_delivery_fee }) || retail_delivery_fee || 0.0,
          delivery_fee_discounts_total: cached_amount.delivery_fee_discounts_total || get_liquidcommerce_value('delivery_fee_discounts', -> { shipping_fee_service&.delivery_discount }) || shipping_fee_service&.delivery_discount || 0.0,
          shipping_fee_discounts_total: cached_amount.shipping_fee_discounts_total || get_liquidcommerce_value('shipping_fee_discounts', -> { shipping_fee_service&.shipping_discount }) || shipping_fee_service&.shipping_discount || 0.0,

          # Totals and calculated fields
          deals_total: 0.0,
          discounts_total: cached_amount.discounts_total || get_liquidcommerce_value('discounts_total', -> { discounts_total }) || discounts_total || 0.0,
          total_before_discounts: cached_amount.total_before_discounts || get_liquidcommerce_value('total', -> { total_before_discounts }) || total_before_discounts || 0.0,
          total_before_coupon_applied: cached_amount.total_before_coupon_applied || get_liquidcommerce_value('total', -> { total_before_deals }) || total_before_coupon_applied || 0.0,

          # Fixed values
          shoprunner_total: 0.0,
          # additional_tax_amount: cached_amount.additional_tax_amount || 0.0,
          membership_discount: cached_amount.membership_discount || membership_discount || 0.0,
          membership_shipping_discount: cached_amount.membership_shipping_discount || shipping_fee_service&.membership_shipping_discount || 0.0,
          membership_delivery_discount: cached_amount.membership_delivery_discount || shipping_fee_service&.membership_delivery_discount || 0.0,

          # References
          line_item_id: cached_amount.line_item_id || shipment_amount&.line_item_id
        }

        Rails.logger.info("[LIQUID_COMMERCE] Built attributes with cache values")
      else
        Rails.logger.info("[LIQUID_COMMERCE] No cache found, using original calculation")
        amount_attributes = build_liquidcommerce_amount_attributes
      end

      ActiveRecord::Base.transaction do
        if shipment_amount.present?
          shipment_amount.update!(amount_attributes)
        else
          self.shipment_amount = build_shipment_amount(amount_attributes)
          shipment_amount.save!
        end

        save( validate: false )
        shipment_amount&.line_item&.refresh
      end

      shipment_amount.save( validate: false )
    rescue => e
      Rails.logger.error("[LIQUID_COMMERCE] Save failed: #{e.message}")
      raise
    end
  end

  def build_liquidcommerce_amount_attributes
    {
      sub_total: get_liquidcommerce_value('subtotal', -> { sub_total }),
      taxed_amount: get_liquidcommerce_value('tax_total', -> { tax_total_with_bottle_deposits_and_bag_fees + retail_delivery_fee }),
      shipping_charges: get_liquidcommerce_value('delivery_fee', -> { delivery_fee }),
      fulfillment_fee: get_liquidcommerce_value('fulfillment_fee', -> { shipping_fee_service.fulfillment_fee }),
      taxed_total: get_liquidcommerce_value('total', -> { total }),
      order_items_total: get_liquidcommerce_value('subtotal', -> { sub_total }),
      order_items_tax: get_liquidcommerce_value('product_tax', -> { order_items_tax }),
      shipping_tax: get_liquidcommerce_value('shipping_tax', -> { shipping_tax }),
      bottle_deposits: get_liquidcommerce_value('bottle_deposits', -> { bottle_deposit_fees }),
      bag_fee: get_liquidcommerce_value('bag_fee', -> { bag_fee }),
      engraving_fee: get_liquidcommerce_value('engraving', -> { engraving_fee_without_discounts }),
      engraving_fee_discounts: get_liquidcommerce_value('engraving_discounts', -> { engraving_fee_discounts }),
      engraving_fee_after_discounts: get_liquidcommerce_value('engraving_after_discounts', -> { engraving_fee }),
      gift_card_amount: get_liquidcommerce_value('gift_card_amount', -> { gift_card_amount }),
      coupon_amount: get_liquidcommerce_value('coupon_amount', -> { coupon_amount }),
      retail_delivery_fee: get_liquidcommerce_value('retail_delivery_fee', -> { retail_delivery_fee }),
      deals_total: 0.0,
      discounts_total: 0.0,
      total_before_discounts: get_liquidcommerce_value('total', -> { total_before_discounts }),
      total_before_coupon_applied: get_liquidcommerce_value('total', -> { total_before_deals }),
      shoprunner_total: 0.0,
      additional_tax_amount: 0.0,
      delivery_fee_discounts_total: get_liquidcommerce_value('delivery_fee_discounts', -> { shipping_fee_service.delivery_discount }),
      shipping_fee_discounts_total: get_liquidcommerce_value('shipping_fee_discounts', -> { shipping_fee_service.shipping_discount }),
      membership_discount: 0.0,
      membership_shipping_discount: 0.0,
      membership_delivery_discount: 0.0,
      line_item_id: shipment_amount&.line_item_id
    }
  end

  def shoprunner_eligible?
    order&.shoprunner_token && on_demand?
  end

  def estimate_delivery_fee
    shipping_fee_service.shipping_fee
  end

  def shipment_charge_due_today
    due_today = total_minibar_charge + total_supplier_charge
    not_charged_order_fees = order.order_charges.empty?
    if not_charged_order_fees
      order_fees = order.amounts.service_fee_after_discounts + order.amounts.video_gift_fee
      due_today += order_fees
    end

    due_today.to_f.round_at(2)
  end

  def shipping_fee_service
    @shipping_fee_service ||= ShippingFeeService.new(self)
  end

  def engraving_fee_discount_calculation(percent)
    fee = engraving_fee_without_discounts

    discount = (fee * percent / 100.0).round_at(2)
    [discount, fee].min
  end
end
