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

class CouponMembershipPercent < Coupon
  validates :percent, presence: true

  def minimum_units=(_value)
    super(0)
  end

  private

  def coupon_amount(order)
    [order.membership_price, (order.membership_price * (percent.to_f / 100.0)).round_at(2)].min
  end
end
