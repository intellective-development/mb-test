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

class CouponDecreasingBalance < Coupon
  include Coupon::SegmentSerializer
  include Iterable::Storefront::Serializers::CouponSerializer

  validates :amount, presence: true
  validates :code,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { minimum: 10 }

  has_many :coupon_balance_adjustments, inverse_of: :coupon, foreign_key: 'coupon_id'
  has_one :order, inverse_of: :coupon_decreasing_balance, foreign_key: 'coupon_id'

  #------------------------------------------------------------
  # Class methods
  #------------------------------------------------------------
  def self.disallow_alcohol_discounts?(_order)
    false
  end

  def self.disallow_shipping_discounts?(_order)
    false
  end

  #------------------------------------------------------------
  # Instance methods
  #------------------------------------------------------------
  # Ignores State restrictions as this type of coupons are prepaid
  def qualified_maximum(order)
    qualified_total = qualified_total(order)
    maximum_value && qualified_total > maximum_value ? maximum_value : qualified_total
  end

  def region_eligible?(_order)
    true
  end

  def balance_adjustment_debit_total
    coupon_balance_adjustments.where(debit: true).sum(:amount)
  end

  def balance_adjustment_credit_total
    coupon_balance_adjustments.where(debit: false).sum(:amount)
  end

  def balance
    amount - balance_adjustment_debit_total + balance_adjustment_credit_total
  end

  def balance_for_order(order)
    adjustments = coupon_balance_adjustments.select { |cba| cba.order_id == order.id }
    debits = adjustments.select(&:debit?)
    credits = adjustments.reject(&:debit?)
    debits.sum(&:amount) - credits.sum(&:amount)
  end

  def balance_for_order?(order)
    coupon_balance_adjustments.any? { |cba| cba.order_id == order.id }
  end

  def eligible?(order, at = nil)
    balance.positive? && super
  end

  def redeemed?
    balance < amount
  end

  def purchased_in_order
    order_item.order
  end

  private

  def coupon_amount(order)
    calculate_shipping_and_delivery_amount(balance, order)
  end

  def qualified_total(order)
    qualified_item_total(order) + order.shipping_charges + order.shipping_tax + order.additional_tax + order.tip_amount + order.service_fee + order.engraving_fee + order.bag_fee + order.retail_delivery_fee
  end

  def update_liquid_services
    LiquidCloud::UpdateGiftCardJob.perform_later(id) if Feature[:update_liquid_services].enabled?
  end
end
