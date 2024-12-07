# == Schema Information
#
# Table name: coupons
#
#  id                            :integer          not null, primary key
#  type                          :string(255)      not null
#  code                          :string(255)      not null
#  amount                        :decimal(8, 2)    default(0.0)
#  minimum_value                 :decimal(8, 2)
#  percent                       :integer          default(0)
#  minimum_units                 :integer          default(1)
#  description                   :text             not null
#  combine                       :boolean          default(FALSE), not null
#  starts_at                     :datetime
#  expires_at                    :datetime
#  created_at                    :datetime
#  updated_at                    :datetime
#  maximum_value                 :decimal(8, 2)
#  sellable_type                 :string(255)
#  generated                     :boolean          default(FALSE), not null
#  active                        :boolean          default(TRUE), not null
#  quota                         :integer
#  single_use                    :boolean          default(FALSE), not null
#  nth_order                     :integer
#  free_delivery                 :boolean          default(FALSE), not null
#  restrict_items                :boolean          default(FALSE), not null
#  reporting_type_id             :integer
#  doorkeeper_application_ids    :integer          default([]), is an Array
#  skip_fraud_check              :boolean          default(FALSE), not null
#  order_item_id                 :integer
#  recipient_email               :string
#  send_date                     :date
#  delivered                     :boolean          default(FALSE), not null
#  supplier_type                 :string
#  storefront_id                 :integer
#  engraving_percent             :integer
#  free_service_fee              :boolean          not null
#  nth_order_item                :integer          default(0)
#  free_product_id               :integer
#  free_product_id_nth_count     :integer
#  exclude_pre_sale              :boolean          default(TRUE)
#  sellable_restriction_excludes :boolean          default(FALSE)
#  domain_name                   :string
#  free_shipping                 :boolean          default(FALSE)
#  bulk_coupon_id                :integer
#  membership_plan_id            :bigint(8)
#
# Indexes
#
#  index_coupons_on_code                (code)
#  index_coupons_on_expires_at          (expires_at)
#  index_coupons_on_free_product_id     (free_product_id)
#  index_coupons_on_id_and_type         (id,type)
#  index_coupons_on_lower_code          (lower((code)::text))
#  index_coupons_on_membership_plan_id  (membership_plan_id)
#  index_coupons_on_order_item_id       (order_item_id)
#  index_coupons_on_recipient_email     (recipient_email)
#  index_coupons_on_storefront_id       (storefront_id)
#  index_coupons_on_type                (type)
#
# Foreign Keys
#
#  fk_rails_...  (free_product_id => products.id)
#  fk_rails_...  (storefront_id => storefronts.id)
#

# Coupons are straight forward.  Picture a coupon you have in a grocery store.
# The only big difference in the grocery store you can have 30 coupon for different items you buy.
# For ror-e you can only have one Coupon for an entire order.  This is pretty standard in the ecommerce world.

# The method that is most important:
#
# qualified?
#
# This method does 2 things:
#
# 1) it determines if the items in your cart cost enough to reach the minimum qualifing amount needed for teh coupon to work.
# 2) it determines if the coupon is "eligible?"  (eligible? is a method)
#
#  The eligible? method changes functionality depending on what type of coupon is created.
#    => at the most basic level it determine if the date of the order is greater than starts_at and less than expires_at
#
#  For first_purchase_xxxxx  coupons eligible? also ensures the order that this is being applied
#   to is the first item you have ever purchased.
#
####################################################################################
###  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!  NOTE!!!
###  eligible? uses (order.completed_at || Time.zone.now)
###  thus being accurate for returned items and items being purchased right now.
####################################################################################

class Coupon < ActiveRecord::Base
  include TempStorefrontDefault
  include Coupon::GiftCardMethods

  has_paper_trail

  belongs_to :storefront

  has_many :orders
  has_many :coupon_items, inverse_of: :coupon, autosave: true, dependent: :destroy
  belongs_to :product_type
  belongs_to :reporting_type
  belongs_to :order_item
  belongs_to :free_product, class_name: 'Product', optional: true
  belongs_to :bulk_coupon, optional: true
  belongs_to :membership_plan, optional: true

  has_many :price_tiers
  accepts_nested_attributes_for :price_tiers, allow_destroy: true

  validates :storefront,     presence: true
  validates :code,           presence: true, uniqueness: { case_sensitive: false, scope: :storefront_id }
  validates :description,    presence: true
  validates :starts_at,      presence: true

  DOMAIN_REGEX = /\A(((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}|,|\s)+\z/.freeze
  validates :domain_name, format: { with: DOMAIN_REGEX }, allow_blank: true

  validates :engraving_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, only_integer: true }
  validates :free_product_id_nth_count, numericality: { greater_than_or_equal_to: 1, only_integer: true }, if: -> { free_product_id.present? }
  validates :free_product_id_nth_count, absence: true, if: -> { free_product_id.nil? }
  validates :minimum_value, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :free_shipping,
            inclusion: { in: [false], message: "can't be true for decreasing balance coupons" },
            if: -> { type == 'CouponDecreasingBalance' }
  validates :free_delivery,
            inclusion: { in: [false], message: "can't be true for decreasing balance coupons" },
            if: -> { type == 'CouponDecreasingBalance' }

  scope :at, ->(now) { where('coupons.starts_at <= ?', now).where('coupons.expires_at is null or coupons.expires_at > ?', now) }
  scope :sent, ->(now) { where('coupons.send_date <= ?', now) }
  scope :active,    -> { where(active: true) }
  scope :inactive,  -> { where(active: false) }

  scope :ready_to_deliver,  -> { where('date(send_date) <= ? AND delivered = false', Date.today) }
  scope :gift_card,         -> { joins(order_item: :variant).merge(Variant.gift_card) }
  scope :non_gift_card,     -> { where(order_item: nil) }
  scope :non_referrals,     -> { where.not('description ilike ?', '%referral reward%') }
  scope :not_expired,       ->(now) { where('coupons.expires_at > ?', now) }

  scope :coupon_decreasing_balance,     -> { where(type: 'CouponDecreasingBalance') }
  scope :coupon_not_decreasing_balance, -> { where.not(type: 'CouponDecreasingBalance') }

  before_save :sanitize_code
  before_create :sanitize_code

  after_save :update_liquid_services

  PROMO_CODE_TYPES = %w[CouponPercent CouponValue CouponFirstPurchaseValue CouponFirstPurchasePercent CouponReferral CouponTiered CouponTieredDecreasingBalance].freeze
  GIFT_CART_TYPES = %w[CouponDecreasingBalance].freeze
  MEMBERSHIP_TYPES = %w[CouponMembershipPercent CouponMembershipValue].freeze
  COUPON_TYPES = (GIFT_CART_TYPES + PROMO_CODE_TYPES + MEMBERSHIP_TYPES).freeze

  attr_accessor :c_type

  after_initialize do
    self.engraving_percent = 0 if engraving_percent.nil?
    self.free_service_fee = false if free_service_fee.nil?
    self.minimum_value = 0 if minimum_value.nil?
  end

  #------------------------------------------------------------
  # Class methods
  #------------------------------------------------------------
  def self.disallow_alcohol_discounts?(order)
    # @TODO: consolidate with Deals::LegalRestrictions when it's fixed
    states = ['TX'] & [order&.ship_address&.state&.abbreviation, order&.ship_address&.state_name, order&.promo_address&.fetch('state')]
    states.any?
  end

  def self.disallow_shipping_discounts?(order)
    # @TODO: consolidate with Deals::LegalRestrictions when it's fixed
    states = ['MO'] & [order&.ship_address&.state&.abbreviation, order&.ship_address&.state_name, order&.promo_address&.fetch('state')]
    states.any?
  end

  def self.validate_coupon(code, discount_value = nil)
    if discount_value
      active.where(code: code.downcase).where(amount: discount_value).exists?
    else
      active.where(code: code.downcase).exists?
    end
  end

  def self.find_active_gift_card_by_code(code, storefront)
    Coupon.active.coupon_decreasing_balance.at(Time.zone.now).find_by(code: code.downcase, storefront: storefront)
  end

  def self.find_active_non_gift_card(code, storefront)
    Coupon.active.non_gift_card.at(Time.zone.now).find_by(code: code.downcase, storefront: storefront)
  end

  def self.find_coupon_or_create_if_exists_referrer(code, storefront)
    coupon = Coupon.find_by(code: code.downcase, storefront: storefront)
    return coupon if coupon

    create_if_exists_referrer(code, storefront)
  end

  def self.create_if_exists_referrer(code, storefront)
    referrer = User.find_by(referral_code: code.downcase)
    return nil unless referrer

    CouponReferral.generate_referral_coupon(referrer.referral_code, referrer.name, storefront)
  end

  #------------------------------------------------------------
  # Instance methods
  #------------------------------------------------------------
  def promo_coupon?
    PROMO_CODE_TYPES.include?(type)
  end

  def gift_card_coupon?
    GIFT_CART_TYPES.include?(type)
  end

  def membership_coupon?
    MEMBERSHIP_TYPES.include?(type)
  end

  def active?
    !expired? && active && !quota_filled?
  end

  def inactive?
    !active?
  end

  def free_shipping_or_delivery_coupon?
    free_shipping? || free_delivery?
  end

  def free_shipping?
    free_shipping == true
  end

  def free_delivery?
    free_delivery === true
  end

  def quota_filled?
    return false if quota.blank?

    times_used = orders.finished.count
    times_used >= quota
  end

  def quota_available?
    !quota_filled?
  end

  # amount the coupon will reduce the order
  def value(order)
    order.consider_paid? || order.verifying? || qualified?(order) ? coupon_amount(order) : 0.0
  end

  ##
  # qualified?
  #
  # Collect errors in coupon validation and return a status.
  # Does the coupon meet the criteria to apply it. (is the order price total over the coupon's minimum value)
  #
  # TODO: do not silence the errors. instead they should go upstream and make it to the json?
  def qualified?(order)
    errors = get_errors(order)
    errors.none?
  end

  def nth_order_item?(order)
    order.order_items.sum(:quantity) >= nth_order_item
  end

  def contains_free_product_in_required_quantity?(order)
    return false if free_product_id.blank?

    # getting total number of free_product items in order (there could be different variants)
    total = order.order_items.joins(:variant).where(variants: { product_id: free_product_id }).sum(:quantity)
    total >= free_product_id_nth_count
  end

  def all_finished_orders
    all = orders.finished || []
    all += Order.finished.joins(:coupons).where(coupons: { id: id }) if storefront.enable_multiple_coupons?
    all
  end

  def get_errors(order, at = nil)
    at = Time.zone.now if gift_card? # TECH-3115 gift cards don't need time validation as coupons
    at ||= order.completed_at || Time.zone.now
    errs = []

    errs.append(error_str(:eligible))             unless eligible?(order, at)
    errs.append(error_str(:customer))             unless customer_eligible?(order.user) || order.verifying? || order.consider_paid?
    errs.append(error_str(:email_domain))         unless domain_eligible?(order.try(:user)&.account&.email)
    errs.append(error_str(:region))               unless region_eligible?(order)
    errs.append(error_str(:quota, quota: quota))  unless quota_available? || order.verifying? || order.consider_paid?
    errs.append(error_str(:qualified_item))       unless qualified_item?(order)
    errs.append(error_str(:platform_eligible))    unless platform_eligible?(order)
    errs.append(error_str(:nth_order_item, nth_order_item: nth_order_item)) unless nth_order_item?(order)

    errs.append(error_str(:qualified_order, order: nth_order.to_i.ordinalize)) unless qualified_order?(order.user)
    errs.append(error_str(:free_product)) if free_product_id.present? && !contains_free_product_in_required_quantity?(order)
    errs.append(error_str(:supplier_type, supplier: supplier_type.titleize)) unless qualified_suppliers?(order)
    errs.append(error_str(:minimum_units, minimum_units: minimum_units))       unless minimum_units_met?(order)
    errs.append(error_str(:minimum_value, minimum_value: minimum_value.to_f))  unless minimum_value_exceeded?(order)
    errs.append(error_str(:disallow_alcohol)) if Coupon.disallow_alcohol_discounts?(order) && coupon_amount(order).zero?
    errs.append(error_str(:pre_sale)) if exclude_pre_sale? && only_pre_sale_items?(order)
    errs.append(error_str(:qualified_membership_plan)) unless qualified_membership_plan?(order)

    errs
  end

  def eligible?(order, at = nil) # check timeframe
    at ||= order.completed_at || Time.zone.now
    started?(at) && !expired?(at)
  end

  def eligible_for_first_purchase?(_order, _at = nil)
    # implememnted on coupon_first_purchase
    true
  end

  def platform_eligible?(order)
    doorkeeper_application_ids.any? ? doorkeeper_application_ids.include?(order.doorkeeper_application_id) : true
  end

  # if single use, hasn't used before
  def customer_eligible?(user)
    single_use ? times_used(user) < 1 : true
  end

  def domain_eligible?(user_email)
    return true if domain_name.blank?
    return false if user_email.blank?

    domains = domain_name.split(',').map(&:strip)

    user_email.downcase.end_with?(*domains)
  end

  def shipping_discount_eligible?(order)
    if Coupon.disallow_alcohol_discounts?(order) && Coupon.disallow_shipping_discounts?(order)
      # In Misourri, orders must contain a mixer.
      discountable_items(order).any?
    else
      true
    end
  end

  def shipping_alcohol_discounts?(order)
    if Coupon.disallow_alcohol_discounts?(order)
      # In Indiana, orders must either contain a mixer *OR* have a delivery fee.
      order.shipping_charges.positive? || discountable_items(order).any?
    else
      true
    end
  end

  def region_eligible?(order)
    shipping_discount_eligible?(order) && shipping_alcohol_discounts?(order)
  end

  def minimum_value_exceeded?(order)
    return true unless minimum_value

    value_of_items_to_apply(order) >= minimum_value
  end

  def minimum_units_met?(order)
    number_of_units = order.shipments.load_target.inject(0) do |units, shipment|
      units + shipment.order_items.load_target.sum(&:quantity)
    end

    number_of_units >= (minimum_units || 0)
  end

  def discountable_items(order)
    # If we don't have memoized items for this order, create the array and memoize.
    @discountable_items ||= DiscountableItems.new(self)

    @discountable_items[order]
  end

  # TODO: Need to account for qualified items when figuring out coupon value - do we have situations where
  # we'd not want this to apply.
  def qualified_item?(order)
    all? || coupon_items.none? || coupon_items.any? { |ci| ci.matches_restriction_rules?(order) }
  end

  def qualified_order?(user)
    user_order_count = (user.present? ? user.orders.finished.size + 1 : 1) # if no user, first order
    nth_order.to_i.zero? || user_order_count == nth_order.to_i
  end

  def qualified_suppliers?(order)
    return true if supplier_type.nil?

    order.shipments.all? { |s| s&.supplier&.dashboard_type == supplier_type }
  end

  def qualified_membership_plan?(order)
    return true if membership_plan_id.nil?

    return false if order.user.nil?

    plan_id = order.membership_plan_id || order.membership&.membership_plan_id

    plan_id == membership_plan_id
  end

  def error_str(key, params = {})
    I18n.t(key, { scope: 'coupons.errors' }.merge(params))
  end

  def pending?
    Time.zone.now < starts_at
  end

  def expired?(at = nil)
    return false if expires_at.nil?

    at ||= Time.zone.now
    at > expires_at
  end

  def started?(at = nil)
    at ||= Time.zone.now
    starts_at <= at
  end

  def expire!
    update_attribute(:expires_at, Time.zone.now)
  end

  def all?
    sellable_type == 'All'
  end

  def display_start_time(format = :us_date)
    starts_at ? I18n.localize(starts_at, format: format) : 'N/A'
  end

  def display_expires_time(format = :us_date)
    expires_at ? I18n.localize(expires_at, format: format) : 'N/A'
  end

  def display_send_date(format = :us_date)
    send_date ? I18n.localize(send_date, format: format) : 'N/A'
  end

  def sellable_ids
    coupon_items.pluck(:item_id)
  end

  def sellable_ids=(ids)
    return if ids.blank?

    ids = ids.compact.map(&:to_i).uniq

    if sellable_type.present? && !ids.empty?
      item_type = sellable_type.camelize

      old_persisted_ids = coupon_items.pluck(:item_id)

      if coupon_items.any? { |si| si.item_type != sellable_type }
        coupon_items.delete_all
        old_persisted_ids = []
      end

      added_ids = Set.new(ids).subtract(old_persisted_ids)
      deleted_ids = Set.new(old_persisted_ids).subtract(ids)

      coupon_items.where(item_id: deleted_ids.to_a).delete_all if deleted_ids.present?

      added_ids.each do |item_id|
        coupon_items.build(item_type: item_type, item_id: item_id)
      end
    end
  end

  def applicable_variant_ids
    @applicable_variant_ids ||= find_variant_ids
  end

  def find_variant_ids
    Set.new(coupon_items.flat_map(&:find_variant_ids))
  end

  def send_immediately?
    send_date == Date.today
  end

  def minibar?
    storefront&.business&.default_business?
  end

  def branded?
    sellable_type == 'Brand'
  end

  private

  def times_used(user)
    user ? user.orders.finished.select { |o| o.coupon_code == code }.count : 0
  end

  # dummy method to be called on the specific type of coupon  (single table inheritance)
  def coupon_amount(order)
    amount = value_of_items_to_apply(order)
    calculate_shipping_and_delivery_amount(amount, order)
  end

  def calculate_shipping_and_delivery_amount(amount, order)
    amount += apply_free_shipping(order)
    amount += apply_free_delivery(order)
    apply_max_value(amount, order)
  end

  # This is used in cases where we might want to restrict the maximum value to
  # only qualified items (e.g. if we are running a promotion with a specific brand)
  def qualified_maximum(order)
    qualified_total_amount = if Coupon.disallow_alcohol_discounts?(order)
                               # In Indiana, Tennessee and Texas only mixers and shipping are discountable
                               total = order.additional_tax + discountable_items(order).sum(&:total)
                               # Avoid giving delivery discount twice with coupon and shoprunner
                               total += order.shipping_charges + order.shipping_tax if order.shipping_charges - order.shoprunner_total != 0
                               total
                             elsif Coupon.disallow_alcohol_discounts?(order) && Coupon.disallow_shipping_discounts?(order)
                               # In Missouri only mixers are discountable
                               discountable_items(order).sum(&:total)
                             elsif restrict_items
                               qualified_total(order)
                             else
                               maximum_value
                             end

    maximum_value && qualified_total_amount > maximum_value ? maximum_value : qualified_total_amount
  end

  def qualified_item_total(order)
    discountable_items(order).sum { |item| item.total + item.tax_charge_with_bottle_deposits } || 0
  end

  def qualified_total(order)
    qualified_item_total(order) + order.shipping_charges + order.shipping_tax + order.additional_tax + order.tip_amount + order.bag_fee
  end

  def apply_max_value(amount, order)
    maximum = qualified_maximum(order)
    return amount unless maximum

    [amount, maximum].min
  end

  def apply_free_delivery(order)
    return 0 unless free_delivery

    sum_shipping_charges(order.shipments.on_demand)
  end

  def apply_free_shipping(order)
    return 0 unless free_shipping

    sum_shipping_charges order.shipments.shipped
  end

  def sum_shipping_charges(shipments)
    shipments.filter(&:shipment_amount).sum(&:shipment_shipping_charges)
  end

  def combined_value(order)
    discountable_items(order).sum do |item|
      unless item.price && item.total
        item.set_price_from_variant
        item.calculate_total
      end
      item.total
    end || 0
  end

  def max_price(order)
    discountable_items(order).lazy.map { |item| item.variant.price }.max || 0
  end

  # This is the value of the items that you will apply the coupon on.
  # for combine coupons you apply coupon to all the items
  # otherwise only apply the coupon to the max priced item
  def value_of_items_to_apply(order)
    combine ? combined_value(order) : max_price(order)
  end

  def sanitize_code
    self.code = code.downcase
  end

  def self.admin_grid(params = {})
    grid = Coupon.public_send(Kaminari.config.page_method_name, params[:page] || 1)
                 .per(params[:per_page] || 15)
                 .order(id: :desc)
    grid = grid.includes(%i[storefront order_item])
    grid = grid.where('code ILIKE ?', "%#{params[:search].squish.downcase}%") if params[:search].present?
    grid = grid.where('expires_at IS NULL OR expires_at > ?', Time.zone.now) if params[:include_expired].blank?
    grid = grid.where(generated: false) if params[:hide_generated].present?
    grid = grid.where(storefront_id: params[:storefront_id]) if params[:storefront_id].present?
    grid
  end

  def only_pre_sale_items?(order)
    return false if order.order_items.empty?

    order.order_items.reject(&:in_pre_sale?).empty?
  end

  class DiscountableItems < Hash
    extend Forwardable
    def_delegators :@coupon, :applicable_variant_ids

    def initialize(coupon)
      @coupon = coupon
      super(nil)
    end

    def restrict_items?
      @coupon.restrict_items? && !@coupon.all? || @coupon.coupon_items.exists?
    end

    def default(order)
      self[order] = order.shipments.load_target.flat_map do |shipment|
        items = shipment.order_items.load_target
        items = exclude_gift_card_items(items)
        items = exclude_pre_sale_items(items)

        if @coupon.class.disallow_alcohol_discounts?(order)
          items.select { |item| item&.product&.hierarchy_category_name == 'mixers' }
        elsif restrict_items?
          items.select { |item| applicable_variant_ids.include?(item.variant_id) }
        else
          items
        end
      end
    end

    # TODO: remove when clean up the enable_new_coupon_message ff
    def exclude_pre_sale_items(items)
      return items unless @coupon.exclude_pre_sale

      items.reject(&:in_pre_sale?)
    end

    def exclude_gift_card_items(items)
      items.reject(&:gift_card?)
    end
  end

  def update_liquid_services
    LiquidCloud::UpdateCouponJob.perform_later(id) if Feature[:update_liquid_services].enabled?
  end
end
