# == Schema Information
#
# Table name: order_amounts
#
#  id                                :integer          not null, primary key
#  taxed_total                       :decimal(8, 2)    default(0.0)
#  sub_total                         :decimal(8, 2)    default(0.0)
#  shipping_charges                  :decimal(8, 2)    default(0.0), not null
#  taxed_amount                      :decimal(8, 2)    default(0.0), not null
#  coupon_amount                     :decimal(8, 2)    default(0.0), not null
#  tip_amount                        :decimal(8, 2)    default(0.0), not null
#  created_at                        :datetime
#  updated_at                        :datetime
#  order_id                          :integer
#  total_before_discounts            :decimal(8, 2)    default(0.0)
#  bottle_deposits                   :decimal(8, 2)    default(0.0), not null
#  order_items_tax                   :decimal(8, 2)    default(0.0)
#  order_items_total                 :decimal(8, 2)    default(0.0)
#  shipping_tax                      :decimal(8, 2)    default(0.0), not null
#  deals_total                       :decimal(8, 2)    default(0.0)
#  discounts_total                   :decimal(8, 2)    default(0.0)
#  total_before_coupon_applied       :decimal(8, 2)    default(0.0)
#  shoprunner_total                  :decimal(8, 2)    default(0.0)
#  tip_eligible_amount               :decimal(8, 2)    default(0.0)
#  shipping_after_discounts          :decimal(8, 2)    default(0.0)
#  additional_tax                    :decimal(8, 2)    default(0.0)
#  gift_card_amount                  :decimal(8, 2)    default(0.0)
#  service_fee                       :decimal(8, 2)    default(0.0)
#  bag_fee                           :decimal(8, 2)    default(0.0), not null
#  service_fee_discounts             :decimal(8, 2)    default(0.0)
#  engraving_fee                     :decimal(8, 2)    default(0.0), not null
#  engraving_fee_discounts           :decimal(8, 2)    default(0.0)
#  engraving_fee_after_discounts     :decimal(8, 2)    default(0.0)
#  delivery_fee_discounts_total      :decimal(8, 2)    default(0.0), not null
#  shipping_fee_discounts_total      :decimal(8, 2)    default(0.0), not null
#  video_gift_fee                    :decimal(9, 2)    default(0.0)
#  current_charge_total              :decimal(8, 2)    default(0.0)
#  deferred_charge_total             :decimal(8, 2)    default(0.0)
#  retail_delivery_fee               :decimal(9, 2)    default(0.0)
#  membership_discount               :decimal(8, 2)
#  membership_price                  :decimal(8, 2)
#  membership_tax                    :decimal(8, 2)
#  membership_service_fee_discount   :decimal(8, 2)
#  membership_engraving_fee_discount :decimal(8, 2)
#  membership_shipping_discount      :decimal(8, 2)
#  membership_on_demand_discount     :decimal(8, 2)
#  fulfillment_fee                   :decimal(8, 2)
#  delivery_after_discounts          :decimal(8, 2)
#
# Indexes
#
#  index_order_amounts_on_order_id  (order_id)
#

class OrderAmount < ActiveRecord::Base
  extend MigratingAttributes
  migrate_attribute :total_before_coupon, to: :total_before_discounts, warning: true
  attr_accessor :skip_coupon_creation

  attribute :delivery_after_discounts, :decimal, default: 0.0

  belongs_to :order

  validates :order, presence: true

  after_create :create_balance_adjustment

  delegate :free_product_discount, to: :amounts
  delegate :total_coupon_available, to: :amounts
  delegate :membership_plan, to: :amounts
  delegate :membership_coupon_discount, to: :amounts
  delegate :potential_membership_savings, to: :amounts
  delegate :sales_tax, to: :amounts
  delegate :total_taxed_amount, to: :amounts

  def process_gift_card_balance(remaining_engraving_fee_balance, remaining_service_fee_balance)
    return if order.coupons.empty?

    order_balance = order.total_before_coupon_applied

    # subtract the promo code from the order balance before coupon adjustments
    order_balance -= order.coupon.value(order) unless order.coupon.nil?

    order.coupons.select(&:gift_card_coupon?).each do |gift_card|
      next if order_balance == 0.0 && remaining_engraving_fee_balance.zero? && remaining_service_fee_balance.zero?

      gift_card.coupon_balance_adjustments.where(order_id: order.id).destroy_all
      coupon_amount = gift_card.value(order)
      coupon_total = gift_card.balance
      amount = coupon_amount
      if order_balance > coupon_amount
        order_balance -= coupon_amount
      else
        amount = order_balance
        order_balance = 0.0
      end

      next if amount.negative?

      remaining_coupon_balance = coupon_total - amount

      if order_balance.zero? && remaining_coupon_balance.positive? && remaining_engraving_fee_balance.positive?
        discounted_value = get_value_to_be_discounted(remaining_coupon_balance, remaining_engraving_fee_balance)
        amount += discounted_value
        remaining_coupon_balance -= discounted_value
        remaining_engraving_fee_balance -= discounted_value
      end
      # discount service fee if we can
      if order_balance.zero? && remaining_coupon_balance.positive? && remaining_service_fee_balance.positive?
        discounted_value = get_value_to_be_discounted(remaining_coupon_balance, remaining_service_fee_balance)
        amount += discounted_value
        remaining_coupon_balance -= discounted_value
        remaining_service_fee_balance -= discounted_value
      end

      Coupon::CreateBalanceAdjustmentWorker.perform_async(gift_card.id,
                                                          order_id: order.id,
                                                          debit: true,
                                                          amount: amount)
    end
  end

  def service_fee_after_discounts
    service_fee - service_fee_discounts
  end

  def remaining_coupon_value_before_engraving_fee
    remaining_balance = total_coupon_available - coupon_value
    return 0.0 unless remaining_balance.positive?

    remaining_balance
  end

  def delivery_charges
    shipping = {
      shipping: 0.0,
      on_demand: 0.0
    }
    order.shipments.each do |shipment|
      if shipment.shipping_method&.shipped?
        shipping[:shipping] += shipment.shipment_shipping_charges || 0.0
      elsif shipment.shipping_method&.on_demand?
        shipping[:on_demand] += shipment.shipment_shipping_charges || 0.0
      end
    end
    shipping[:shipping] = shipping[:shipping].to_f.round_at(2)
    shipping[:on_demand] = shipping[:on_demand].to_f.round_at(2)
    shipping
  end

  def get_value_to_be_discounted(remaining_coupon_balance, value_to_apply)
    return value_to_apply if value_to_apply < remaining_coupon_balance

    remaining_coupon_balance
  end

  #-------------------------------------
  # Instance methods
  #-------------------------------------
  def create_balance_adjustment
    return if skip_coupon_creation # to handle it manually on the place itself

    service_fee_discounted = false
    remaining_engraving_fee_balance = order.engraving_fee_discounts
    remaining_service_fee_balance = order.service_fee_discounts

    # to keep compatibility with old mobile app versions
    # if the promo code field has a gift card we should make a balance adjustment
    if order.coupon.is_a?(CouponDecreasingBalance)
      order_total = order.total_before_coupon_applied
      coupon_value = order.coupon.value(order)
      coupon_total = order.coupon.balance
      remaining_coupon_balance = coupon_total - coupon_value
      # discount engraving if we can
      if order_total < coupon_value && remaining_engraving_fee_balance.positive?
        discounted_value = get_value_to_be_discounted(remaining_coupon_balance, remaining_engraving_fee_balance)
        coupon_value += discounted_value
        remaining_coupon_balance -= discounted_value
        remaining_engraving_fee_balance -= discounted_value
      end
      # discount service fee if we can
      if order_total < coupon_value && remaining_coupon_balance.positive?
        discounted_value = get_value_to_be_discounted(remaining_coupon_balance, remaining_service_fee_balance)
        coupon_value += discounted_value
        remaining_coupon_balance -= discounted_value
        remaining_service_fee_balance -= discounted_value
      end
      Coupon::CreateBalanceAdjustmentWorker.perform_async(order.coupon_id,
                                                          order_id: order.id,
                                                          debit: true,
                                                          amount: coupon_value)

    end

    process_gift_card_balance(remaining_engraving_fee_balance, remaining_service_fee_balance)
  end

  def sub_total_with_engraving
    sub_total + engraving_fee
  end

  def tax_discounting_bottle_fee
    taxed_amount - bottle_deposits
  end

  def coupon_value
    [total_coupon_available, total_before_coupon_applied].min
  end

  def coupon_amount_share
    [
      coupon_amount,
      membership_plan&.no_service_fee? ? 0 : service_fee_discounts,
      engraving_fee_discounts_without_membership_discount,
      free_product_discount,
      membership_coupon_discount
    ].reduce(:-)
  end

  def gift_card_amount_share
    [
      gift_card_amount.to_f,
      membership_plan&.no_service_fee? ? 0 : service_fee_discounts,
      engraving_fee_discounts_without_membership_discount,
      free_product_discount,
      membership_coupon_discount
    ].reduce(:-)
  end

  def engraving_fee_discounts_without_membership_discount
    return engraving_fee_discounts unless membership_engraving_fee_discount.present?

    engraving_fee_discounts - membership_engraving_fee_discount
  end

  def membership_price
    super || 0.0
  end

  def delivery_after_discounts
    super || 0.0
  end

  def outstanding
    amounts.outstanding(self)
  end

  def service_fee
    @service_fee || super || 0.0
  end

  def override_service_fee(service_fee)
    @service_fee = service_fee
  end

  private

  def amounts
    Order::Amounts.new(order)
  end
end
