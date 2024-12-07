# == Schema Information
#
# Table name: orders
#
#  id                        :integer          not null, primary key
#  number                    :string(255)
#  ip_address                :string(255)
#  email                     :string(255)
#  state                     :string(255)
#  user_id                   :integer
#  bill_address_id           :integer
#  payment_profile_id        :integer
#  ship_address_id           :integer
#  coupon_id                 :integer
#  active                    :boolean          default(TRUE), not null
#  completed_at              :datetime
#  created_at                :datetime
#  updated_at                :datetime
#  tip_amount                :decimal(8, 2)    default(0.0)
#  confirmed_at              :datetime
#  delivery_notes            :text
#  cancelled_at              :datetime
#  courier                   :boolean          default(FALSE), not null
#  platform                  :string(255)      default("web")
#  trak_id                   :string(255)
#  scheduled_for             :datetime
#  visit_id                  :integer
#  client                    :string(255)
#  fraud_score               :float            default(0.0)
#  subscription_id           :string(255)
#  ip_geolocation            :string(255)
#  device_udid               :string(255)
#  doorkeeper_application_id :integer
#  button_referrer_token     :string(255)
#  gift_detail_id            :integer
#  pickup_detail_id          :integer
#  shoprunner_token          :string(255)
#  delivery_service_order    :jsonb
#  birthdate                 :string
#  allow_substitution        :boolean          default(FALSE), not null
#  fraud_reported_at         :datetime
#  storefront_id             :integer          not null
#  storefront_uuid           :string
#  storefront_cart_id        :string
#  cart_id                   :integer
#  membership_id             :integer
#  membership_plan_id        :integer
#  finalized_at              :datetime
#  metadata                  :jsonb
#
# Indexes
#
#  index_orders_on_bill_address_id     (bill_address_id)
#  index_orders_on_cart_id             (cart_id)
#  index_orders_on_completed_at        (completed_at)
#  index_orders_on_coupon_id           (coupon_id)
#  index_orders_on_device_udid         (device_udid)
#  index_orders_on_gift_detail_id      (gift_detail_id)
#  index_orders_on_membership_id       (membership_id)
#  index_orders_on_membership_plan_id  (membership_plan_id)
#  index_orders_on_number              (number) UNIQUE
#  index_orders_on_payment_profile_id  (payment_profile_id)
#  index_orders_on_pickup_detail_id    (pickup_detail_id)
#  index_orders_on_ship_address_id     (ship_address_id)
#  index_orders_on_state               (state)
#  index_orders_on_storefront_id       (storefront_id)
#  index_orders_on_storefront_uuid     (storefront_uuid)
#  index_orders_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (membership_id => memberships.id)
#  fk_rails_...  (membership_plan_id => membership_plans.id)
#  fk_rails_...  (pickup_detail_id => pickup_details.id)
#  fk_rails_...  (storefront_id => storefronts.id)
#
class Order < ApplicationRecord
  class_attribute :force_ensure_unique_number, default: false
  # include BarOS::MiniBar::Orders::Hooks
  include BarOS::Orders::Hooks

  extend FriendlyId

  include TempStorefrontDefault
  include MachineAdapter
  include Order::SegmentSerializer
  include Iterable::Storefront::Serializers::OrderSerializer
  include Statesman::Adapters::ActiveRecordQueries
  include Order::MetadataField
  include Order::Trackable

  # Temporary address to validate coupons and deals when a full ship_address has not been created.
  # This is not saved to database.
  attr_accessor :promo_address

  # Temporary flag for Liquid Cloud orders
  attr_accessor :liquid

  FINISHED_STATES = %w[canceled confirmed delivered paid scheduled verifying placed].freeze
  SUPPLIER_VISIBLE_STATES = %w[canceled confirmed delivered paid scheduled pre_sale back_order placed].freeze
  PROCESSED_STATES = %w[confirmed delivered].freeze
  TRACKABLE_STATES = %w[confirmed paid scheduled placed].freeze
  CONSIDER_PAID_STATES = %w[paid canceled scheduled confirmed delivered].freeze

  RETRY_LIMIT = 10

  statesman_machine machine_class: Order::OrderStateMachine, transition_class: OrderTransition

  friendly_id :number, use: [:finders]

  acts_as_taggable

  has_many :order_transitions, dependent: :destroy, autosave: false
  has_one :last_order_transition, -> { where(most_recent: true) }, class_name: 'OrderTransition'
  has_one :verifying_transition, -> { where(to_state: 'verifying').order(created_at: :desc) }, class_name: 'OrderTransition'

  has_many :shipments, inverse_of: :order
  has_many :charges, through: :shipments
  has_many :chargeables
  has_many :order_charges
  has_many :comments, as: :commentable
  has_many :applied_deals, through: :shipments
  has_many :order_adjustments, through: :shipments
  has_many :order_items, through: :shipments
  has_many :order_suppliers, through: :shipments, source: :supplier, inverse_of: :orders
  has_many :products, through: :order_items, source: :product
  has_many :product_size_groupings, through: :products, source: :product_size_grouping
  has_many :product_grouping_tags, through: :product_size_groupings, source: :tags
  has_many :brands, through: :product_size_groupings
  has_many :hierarchy_categories, through: :product_size_groupings
  has_many :hierarchy_types, through: :product_size_groupings
  has_many :hierarchy_subtypes, through: :product_size_groupings
  has_many :shipping_methods, through: :shipments
  has_many :suppliers, through: :shipments
  has_many :support_interactions
  has_many :variants, through: :order_items
  has_many :coupon_balance_adjustments
  has_many :disputes

  has_one :first_shipment, ->(instance) { first_for_order(instance.id) }, class_name: 'Shipment'
  has_one :fraud_record, class_name: 'FraudulentOrder'
  has_one :fraud_score
  has_one :loyalty_transaction
  has_one :order_amount
  has_one :order_survey
  has_one :sift_decision, class_name: 'Sift::Decision', as: :subject
  has_one :subscription, foreign_key: 'base_order_id'
  has_one :video_gift_message
  has_one :payment_profile_update_link, -> { where('used_at IS NULL AND expire_at > ?', Time.now.utc) }

  belongs_to :cart, optional: true
  belongs_to :storefront
  belongs_to :bill_address, class_name: 'Address'
  belongs_to :coupon
  belongs_to :coupon_decreasing_balance, foreign_key: 'coupon_id', inverse_of: :order
  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'
  belongs_to :gift_detail, autosave: true
  belongs_to :payment_profile
  belongs_to :pickup_detail
  belongs_to :ship_address, class_name: 'Address'
  belongs_to :user
  belongs_to :membership, optional: true, inverse_of: :orders
  belongs_to :membership_plan, optional: true, inverse_of: :orders

  has_one :account, through: :user, source_type: 'RegisteredAccount'

  has_and_belongs_to_many :coupons

  delegate :email, :name,     to: :account,       prefix: 'user'
  delegate :phone,            to: :bill_address,  prefix: 'bill_address'
  delegate :phone,            to: :ship_address,  prefix: 'ship_address',   allow_nil: true
  delegate :phone,            to: :pickup_detail, prefix: 'pickup_detail',  allow_nil: true
  delegate :code,             to: :coupon,        prefix: true,             allow_nil: true
  delegate :vip?,             to: :user,                                    allow_nil: true

  delegate :tip_amount,                    to: :amounts
  delegate :taxed_total,                   to: :amounts
  delegate :shipping_after_discounts,      to: :amounts
  delegate :delivery_after_discounts,      to: :amounts
  delegate :shipping_charges,              to: :amounts
  delegate :shipping_tax,                  to: :amounts
  delegate :additional_tax,                to: :amounts
  delegate :deals_total,                   to: :amounts
  delegate :shoprunner_total,              to: :amounts
  delegate :discounts_total,               to: :amounts
  delegate :total_before_coupon_applied,   to: :amounts
  delegate :total_before_discounts,        to: :amounts
  delegate :sub_total,                     to: :amounts
  delegate :sub_total_with_engraving,      to: :amounts
  delegate :service_fee,                   to: :amounts
  delegate :service_fee_discounts,         to: :amounts
  delegate :service_fee_after_discounts,   to: :amounts
  delegate :retail_delivery_fee,           to: :amounts
  delegate :order_items_total,             to: :amounts
  delegate :bottle_deposits,               to: :amounts
  delegate :bag_fee,                       to: :amounts
  delegate :engraving_fee,                 to: :amounts
  delegate :engraving_fee_discounts,       to: :amounts
  delegate :engraving_fee_after_discounts, to: :amounts
  delegate :total_taxed_amount,            to: :amounts
  delegate :taxed_amount,                  to: :amounts
  delegate :tax_discounting_bottle_fee,    to: :amounts
  delegate :order_items_tax,               to: :amounts
  delegate :coupon_amount,                 to: :amounts
  delegate :coupon_amount_share,           to: :amounts
  delegate :gift_card_amount,              to: :amounts
  delegate :gift_card_amount_share,        to: :amounts
  delegate :tip_eligible_amount,           to: :amounts
  delegate :video_gift_fee,                to: :amounts
  delegate :total_before_coupon_applied,   to: :amounts_without_digital_shipments, prefix: :without_digital
  delegate :current_charge_total,          to: :amounts
  delegate :deferred_charge_total,         to: :amounts
  delegate :membership_discount,           to: :amounts
  delegate :membership_price,              to: :amounts
  delegate :membership_tax,                to: :amounts
  delegate :membership_coupon_discount,    to: :amounts
  delegate :membership_service_fee_discount, to: :amounts
  delegate :membership_engraving_fee_discount, to: :amounts
  delegate :membership_shipping_discount,  to: :amounts
  delegate :membership_on_demand_discount, to: :amounts
  delegate :potential_membership_savings,  to: :amounts
  delegate :fulfillment_fee,               to: :amounts
  delegate :sales_tax,                     to: :amounts

  delegate :flagged?, to: :fraud_score, allow_nil: true

  delegate :name, to: :doorkeeper_application, prefix: true, allow_nil: true

  before_validation :set_email, if: :set_email?
  before_validation :set_number, unless: :number?

  validates :email, presence: true, format: { with: CustomValidators::Emails.email_validator }
  validates :number, :user, presence: true
  validates :storefront_uuid, uniqueness: { case_insensitive: false }, allow_nil: true

  after_initialize :set_storefront_uuid, if: -> { new_record? }
  after_save :reindex_async, if: :state_changed?

  accepts_nested_attributes_for :shipments, allow_destroy: true

  #--------------------------------------------------
  # Scopes
  #--------------------------------------------------
  scope :pending,        -> { in_state('in_progress') }
  scope :canceled,       -> { in_state('canceled') }
  scope :finished,       -> { in_state(FINISHED_STATES) }
  scope :processed,      -> { in_state(PROCESSED_STATES) }
  scope :scheduled,      -> { in_state('scheduled') }
  scope :unconfirmed,    -> { in_state('paid') }
  scope :search_import,  -> { includes([:gift_detail, :shipments, :ship_address, { user: [:account] }]) }
  scope :completed_desc, -> { order('completed_at DESC') }
  scope :excluding_self,      ->(order_id) { where.not(id: order_id) }
  scope :by_membership_id, ->(membership_id) { where(membership_id: membership_id) }
  scope :by_email_or_contact, lambda { |email_address|
    includes(:account).finished.where(email: email_address).references(:registered_accounts)
                      .or(finished.includes(:account).where("registered_accounts.email": email_address).references(:registered_accounts))
                      .or(finished.includes(:account).where("registered_accounts.contact_email": email_address).references(:registered_accounts))
  }

  #-----------------------------------
  # Class methods
  #-----------------------------------

  #-----------------------------------
  # SearchKick
  #-----------------------------------
  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             word_end: [:number],
             batch_size: 200,
             searchable: %i[address1 company delivery_name gift_email gift_message gift_phone
                            gift_recipient number phone user_email user_name external_shipment_ids external_partner_id]

  scope :search_import, -> { includes(%i[gift_detail shipments ship_address charges user]) }

  def should_index?
    consider_paid? || verifying? || placed?
  end

  def search_data
    {
      address1: ship_address&.address1,
      company: ship_address&.company,
      completed_at: completed_at || created_at,
      delivery_name: ship_address&.name,
      gift_email: gift_detail&.recipient_email,
      gift_message: gift_detail&.message,
      gift_phone: gift_detail&.recipient_phone,
      gift_recipient: gift_detail&.recipient_name,
      number: number,
      order_state: state,
      storefront: storefront_id,
      phone: ship_address&.phone,
      suppliers: shipments.pluck(:supplier_id),
      transaction_ids: charges.pluck(:transaction_id),
      user_email: email,
      user_id: user.id,
      user_name: user.name,
      external_shipment_ids: shipments.pluck(:external_shipment_id).compact,
      external_partner_id: partner_order_id
    }
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def pickup?
    pickup_detail.present?
  end

  def save(*)
    set_default_storefront
    return ensure_unique_number { super } if force_ensure_unique_number?

    User.connection.transaction_open? ? super : ensure_unique_number { super }
  end

  def save!(*)
    set_default_storefront
    return ensure_unique_number { super } if force_ensure_unique_number?

    User.connection.transaction_open? ? super : ensure_unique_number { super }
  end

  def client_source
    case doorkeeper_application_name.to_s.downcase
    when /ios/
      'ios'
    when /android/
      'android'
    else
      'web'
    end
  end

  def amounts(_force_reload: false)
    order_amount || Order::Amounts.new(self)
  end

  def amounts_without_digital_shipments
    AmountsWithoutDigitalShipments.new(self)
  end

  def engraving?
    shipments.paid.any?(&:engraving?)
  end

  def engraving_items
    shipments.paid.select(&:engraving?).map { |s| s.order_items.select(&:engraving?) }.flatten
  end

  def engraving_quantity
    order_items =
      OrderItem
      .joins(:shipment, :item_options)
      .where(shipments: { order_id: id }, item_options: { type: 'EngravingOptions' })
      .where.not(shipments: { state: 'canceled' })
    # TODO: Add cache? @engraving_quantity ||=
    order_items.sum(Arel.sql('COALESCE(quantity, 1)'))
  end

  def engraving_total
    shipments.paid.sum(&:engraving_fee_without_discounts)
  end

  def state
    super || (self[:state] = current_state)
  end

  def publish_order_fraud
    broadcast(:order_flagged_fraud, self)
  end

  def suspected_fraud?
    # Do we think this is a fraud? Has it been shown to suppliers?
    fraud? && !order_transitions.map(&:to_state).include?('paid')
  end

  # These are quick/dirty methods to help CS - we should re-engineer the order processing so they arn't needed!
  #
  # This salvages a complete order, moving it to the paid state.
  def process_complete_order(options = {})
    finalize = FinalizeOrderService.new(self, options)

    unless finalize.process
      cancel_finalize!

      message = finalize.errors.empty? ? 'Unable to process order.' : finalize.errors.values.flatten.to_sentence
      Rails.logger.warn("Order cannot be finalized. #{message}; order id: #{id}")
    end
  end

  def refund_order_charges!
    order_charges.each { |chargeable| chargeable&.charge&.cancel! if chargeable&.charge&.can_be_cancelled? }
  end

  def minibar_charge
    order_charges.where(description: 'Taxes and Fees')&.first&.charge
  end

  # This cancels a complete_order
  def cancel_complete_order
    save_order_amount
    cancel!
  end

  ##
  # Add coupon to order
  #
  # This method is called for both cases when the storefront supports only one coupon or multiple coupons.
  # A decision is made to choose on how we are adding the coupon.
  #
  # TODO: remove single coupon relationship and validate one or many by the storefront flag.
  #
  def add_coupon(coupon)
    self.coupon_id = nil

    # make sure we can apply this coupon to this order
    if Feature[:enable_new_coupon_message].enabled?
      eligible, = Coupons::CouponEligibilityService.new(self).eligible?(coupon)
    else
      eligible = coupon&.qualified?(self)
    end
    return false unless eligible

    if storefront.enable_multiple_coupons?
      coupons.push(coupon) unless coupons.include?(coupon)
      coupons.include?(coupon)
    else
      self.coupon = coupon
      coupon && self.coupon == coupon
    end
  end

  def notify_fraudulent_coupon(coupon)
    # Check if promo abuse was reported less than 10 minutes ago
    return if fraud_reported_at && fraud_reported_at + 10.minutes >= Time.now

    self.fraud_reported_at = Time.now

    InternalAsanaNotificationWorker.perform_async(
      tags: [AsanaService::PROMO_ABUSE_TAG_ID],
      name: "Fraudulent Promo #{coupon.code} for Order #{number} - #{user_name}",
      notes: "Sift detected an attempt to abuse a promo code. \n\nOrder: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{id}/edit \n\nSift: https://console.siftscience.com/users/#{user.referral_code}/?abuse_type=promotion_abuse"
    )
  end

  # This one is used from MINIADMIN so it doesn't requires promo abuse check
  def add_gift_card!(gift_card)
    if gift_card.qualified?(self)
      return if coupons.include?(gift_card)

      coupons.push(gift_card)
    else
      raise "The code '#{String(gift_card.code).upcase}' is invalid"
    end
  end

  def create_coupon_adjustment_and_update_amounts!(coupon:, amount:, debit:, skip_coupon_creation: true)
    coupon.coupon_balance_adjustments.create!(amount: amount, debit: debit, order_id: id)
    save_order_amount(skip_coupon_creation: skip_coupon_creation)
  end

  def add_gift_cards(gift_cards)
    self.coupons += gift_cards.map do |gift_card|
      error_message = "The code '#{String(gift_card.code).upcase}' is invalid"

      raise error_message unless gift_card.qualified?(self)

      gift_card
    end
  end

  def amount_covered_with_coupon
    debits = coupon_balance_adjustments.select(&:debit?)
    credits = coupon_balance_adjustments.reject(&:debit?)
    debits.sum(&:amount) - credits.sum(&:amount)
  end

  def amount_covered_by_coupon(coupon_id)
    balance_adjustments = CouponBalanceAdjustment.where(order_id: id, coupon_id: coupon_id)
    debits = balance_adjustments.select(&:debit?)
    credits = balance_adjustments.reject(&:debit?)
    debits.sum(&:amount) - credits.sum(&:amount)
  end

  def tax_exempt?
    return false unless user

    user.tax_exempt?(completed_at || Time.zone.now)
  end

  def late_confirmation?
    state == 'paid' && shipments.any?(&:late_confirmation?)
  end

  def trak?
    trak_id.present?
  end

  def covered_by_coupon?
    amount_covered_with_coupon >= total_before_coupon_applied
  end

  def covered_by_discounts?
    taxed_total.zero?
  end

  def consider_paid?
    CONSIDER_PAID_STATES.include?(current_state)
  end

  # Call after the order has been confirmed by the supplier.
  def order_confirmed!
    return if confirmed?

    confirm!
    Order::ConfirmShipmentsWorker.new.perform(id) # inline until told otherwise.
  end

  def confirm_digital_shipments!
    shipments.digital.reject { |sh| sh.state == 'confirmed' }.each(&:confirm!)
  end

  def order_canceled!(send_confirmation_email: false, reason_id: nil)
    # TODO: Transition this to an event triggered by state transition - currently it is only being fired when the conditional is met.
    # broadcast(:order_canceled, self, send_confirmation_email) if send_confirmation_email && taxed_total.to_f.positive?

    OrderCancellationNotifierWorker.perform_async(id) if send_confirmation_email && taxed_total.to_f.positive?
    publish_order_fraud if OrderAdjustmentReason.find_by(id: reason_id)&.fraud?
    cancel! if can_transition_to?(:canceled)
  end

  def eligible_for_order_survey?
    !canceled? &&
      shipping_methods.none?(&:shipped?) &&
      Feature[:order_surveys].enabled?(user) &&
      (user.test_group <= 80) # 80% of Users will get served google merchant review instead
  end

  def eligible_for_yotpo_review?
    return false if shipments.digital.exists?

    !(shipments.map(&:scheduled_for?).any? || shipping_methods.map(&:shipped?).any?)
  end

  def eligible_for_referral_credit?
    coupon&.type == 'CouponReferral' && !canceled?
  end

  def eligible_total_for_tipping
    shipments.inject(0.0) do |total, shipment|
      shipment.shipping_method&.allows_tipping ? total + shipment.sub_total : total
    end
  end

  def tip_amount=(amount)
    amount = amount.to_f
    amount.negative? ? super(0.0) : super(amount)
  end

  def tax_time
    completed_at || Time.current
  end

  def adjustable?
    completed_at && payment_profile.present? && payment_profile.payment_type != PaymentProfile::AFFIRM
  end

  def gift?
    gift_detail_id.present?
  end

  def delivery_name
    if gift?
      [gift_detail.recipient_name.presence || ship_address&.name, ship_address&.company].compact.join(' - ')
    else
      ship_address&.name_line
    end
  end

  def fraud?
    fraud_record.present? || sift_decision&.fraud? || user&.sift_decision&.fraud?
  end

  def save_order_amount(skip_coupon_creation: false, **unused_args)
    raise ArgumentError, "Unexpected positional arguments: #{unused_args.keys}" unless unused_args.empty?

    attrs = Order::Amounts.new(self, order_amount).to_attributes.merge(skip_coupon_creation: skip_coupon_creation)
    if order_amount.present?
      order_amount.update(attrs)
    else
      # make sure order is saved before creating order_amount
      save if new_record?
      create_order_amount(attrs)
    end
  end

  def processed?
    in_state?(PROCESSED_STATES)
  end

  def all_gift_card_coupons
    all_coupons.select { |coupon| coupon.is_a?(CouponDecreasingBalance) }
  end

  def all_coupons
    Array.wrap(coupon) + coupons.to_a
  end

  def related_coupon_codes
    ([coupon&.code] + coupons.pluck(:code)).compact
  end

  def engraving_discount_percent
    # there should be at max one coupon with engraving_percent, all others will have it set to 0
    percent = all_coupons.map(&:engraving_percent).max.to_f

    percent += membership_plan_record.engraving_percent_off.to_f if membership_plan_record&.apply_engraving_percent_off?

    percent > 100 ? 100 : percent
  end

  def reindex_async
    reindex
    shipments&.find_each { |shipment| ShipmentReindexWorker.perform_async(shipment.id) }
  end

  def contains_digital_shipments?
    shipments.digital.exists?
  end

  def digital?
    shipments.any? && shipments.all?(&:digital?)
  end

  def ship_address_state
    ship_address&.state&.abbreviation || ship_address&.state_name || promo_address&.fetch('state')
  end

  def first_paid_order_of_user?
    paid? && user.orders.joins(:order_transitions).where(order_transitions: { to_state: :paid }).count == 1
  end

  def new_buyer_candidate?
    user.orders.joins(:order_transitions).where(order_transitions: { to_state: :paid }).count.zero?
  end

  def corporate?
    # TECH-3398
    return true if user.corporate_email?
    return true if delivery_notes.to_s.downcase =~ /freight|security|reception/

    ship_address && ship_address.full_address_array.join('').downcase =~ /floor|suite/
  end

  def user_tagged_corporate?
    user.corporate?
  end

  def first_corporate_order_from_user?
    first_paid_order_of_user?
  end

  def gift_card_amounts_list
    list = {}
    list[coupon.code] = { type: 'Promo Code', amount: coupon_amount - gift_card_amount } if coupon.present? && !coupon.is_a?(CouponDecreasingBalance)

    coupon_balance_adjustments.each do |cba|
      list[cba.coupon.code] ||= { type: 'Gift Card', amount: 0 }
      list[cba.coupon.code][:amount] += cba.debit? ? cba.amount : -cba.amount
    end
    list
  end

  def admin_url
    "/admin/fulfillment/orders/#{number}/edit"
  end

  def order_items_count
    shipments.sum(&:item_count)
  end

  def recalculate_and_apply_taxes(fallback_address = nil, should_set_default_tip = false)
    if Feature[:threaded_tax_calculation].enabled?
      MetricsClient::Metric.emit('feature.threaded_tax_calculation.enabled', 1)
      recalculate_and_apply_taxes_concurrent(fallback_address)
    else
      MetricsClient::Metric.emit('feature.threaded_tax_calculation.enabled', 0)
      shipments.each { |shipment| shipment.recalculate_and_apply_taxes(fallback_address) }

      avalara_order_tax_service(fallback_address)
    end

    DefaultTipService.new(self).calculate if should_set_default_tip

    save_order_amount(skip_coupon_creation: true)
  end

  def video_gift_order?
    video_gift_fee.positive?
  end

  def disable_in_stock_check?
    !storefront.default_storefront? && storefront.enable_in_stock_check == false
  end

  def bulk_order?
    # for now we skip payment profile validation if this order is associated to a bulk order order
    BulkOrderOrder.exists?(order_id: id)
  end

  def legacy_rb_paypal_supported?
    !storefront.default_storefront? && order_items_count.positive? && order_items.all? { |order_item| order_item.supplier&.legacy_rb_paypal_supported }
  end

  def minibar?
    storefront&.business&.default_business?
  end

  def cancel_reporting_types
    order_adjustments
      .joins(:reason)
      .merge(OrderAdjustmentReason.cancellation_reasons)
      .map { |order_adjustment| order_adjustment.reason.reporting_type }
  end

  def try_deliver
    deliver! if can_move_to_delivered?
  end

  def all_shipments_delivered?
    shipments.any? && shipments.all? { |shipment| shipment.in_state?(:delivered) }
  end

  def all_shipments_pre_sale_or_back_order?
    shipments.any? && shipments.all? { |s| s.customer_placement_back_order? || s.customer_placement_pre_sale? }
  end

  def can_generate_payment_profile_link?
    shipments.select { |s| !s.customer_placement_standard? && s.exception? }.present? && payment_profile_update_link.blank?
  end

  def can_move_to_delivered?
    shipments.any?(&:delivered?) && shipments.all? { |s| s.delivered? || s.canceled? }
  end

  def local_membership_tax
    return @local_membership_tax if defined?(@local_membership_tax)

    @local_membership_tax || order_amount.present? ? membership_tax : 0.0
  end

  def membership_plan_record
    membership || membership_plan
  end

  def taxes_and_fees_chargeables
    order_charges.includes(:charge) + order_adjustments.includes(:charge, :customer_refunds).where(taxes: true)
  end

  def reschedulable_shipments
    shipments.select(&:can_be_rescheduled?)
  end

  def can_be_rescheduled?
    (consider_paid? || confirmed?) && reschedulable_shipments.present?
  end

  def only_pre_sale_items?
    return false if order_items.empty?

    order_items.reject(&:in_pre_sale?).empty?
  end

  def free_shipping_coupon?
    all_coupons.any?(&:free_shipping?)
  end

  def free_delivery_coupon?
    all_coupons.any?(&:free_delivery?)
  end

  def free_shipping_or_delivery_coupon?
    free_shipping_coupon? || free_delivery_coupon?
  end

  def affirm_supported?
    shipments.none? { |s| s.customer_placement_back_order? || s.customer_placement_pre_sale? }
  end

  private

  def recalculate_and_apply_taxes_concurrent(fallback_address)
    Rails.application.executor.wrap do
      threads = shipments.map do |shipment|
        Thread.new do
          Rails.application.executor.wrap do
            shipment.recalculate_and_apply_taxes(fallback_address)
          end
        end
      end

      threads << Thread.new do
        Rails.application.executor.wrap do
          avalara_order_tax_service(fallback_address)
        end
      end

      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        threads.each(&:join)
      end
    end
  end

  def avalara_order_tax_service(fallback_address)
    tax_calculation = Avalara::OrderTaxService.new(self, fallback_address).calculate_tax
    @local_membership_tax = membership_plan_id.present? ? tax_calculation.get_membership_tax : 0.0
  end

  def set_storefront_uuid
    return if storefront_uuid.present?

    loop do
      self.storefront_uuid = SecureRandom.hex

      break unless Order.exists?(storefront_uuid: storefront_uuid)
    end
  end

  def get_number_with_lock
    time_stamp = 0

    # lock here will make sure there is only one order with a given number for that specific millisecond.
    Order.with_advisory_lock('set order number lock', timeout_seconds: 2) do
      time_stamp = DateTime.now.strftime('%Q').to_i
      time_stamp += 1 until Order.find_by(number: String(time_stamp)).nil?
    end

    time_stamp
  end

  def set_number
    time_stamp = get_number_with_lock
    raise ActiveRecord::RecordNotUnique, 'Failed to set order number' if time_stamp.zero?

    self.number = time_stamp.to_s
  end

  def ensure_unique_number
    raise ArgumentError, 'No block given' unless block_given?

    retries = 0 if retries.nil?
    yield
  rescue ActiveRecord::RecordNotUnique => e
    number_error = e&.message =~ /DETAIL:\s+Key\s\(number\)=\((\d+)\)\salready\sexists/i

    if number_error && retries < RETRY_LIMIT
      retries += 1
      sleep((retries.to_f + rand) / 22)
      set_number
      retry
    else
      raise e
    end
  end

  # Called before validation.  sets the email address of the user to the order's email address
  def set_email
    self.email = user_email
  end

  # Control whether to set user_email >> email
  def set_email?
    # if an account is not present, forget it
    return false unless account

    # at this point, an account must be present.
    # if we don't have an email, set it from account.
    return true unless email?

    # at this point, an account must be present, but we also have an email already set.
    # if the account happens to be guest? and our email is the dummy email, update it.
    # note: account['email'] is the dummy email; account.email intelligently picks between account['email'] and account['contact_email']
    return true if account.guest? && email == account['email']

    # at this point, we must already have an email and it's not a dummy guest email.
    # there's no point in updating anymore.
    false
  end
end
