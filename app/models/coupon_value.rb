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

class CouponValue < Coupon
  validates :amount, presence: true

  def self.generate_code
    code = ('a'..'z').to_a.sort_by { rand }[0..10].join('')
    if Coupon.find_by(code: code).nil?
      code
    else
      generate_code
    end
  end

  def self.generate_referral_reward(user)
    CouponValue.create!(
      storefront: user.account.storefront,
      active: true,
      generated: true,
      code: generate_code,
      description: "Referral Reward for #{user.referral_code}",
      amount: 10,
      minimum_value: 0,
      combine: true,
      quota: 1,
      starts_at: Time.zone.now,
      expires_at: 1.year.since,
      sellable_type: 'All'
    )
  end

  def self.generate_loyalty_reward(storefront)
    CouponValue.create!(
      storefront: storefront,
      active: true,
      generated: true,
      code: generate_code,
      description: 'Loyalty Reward',
      amount: 5,
      minimum_value: 0,
      combine: true,
      quota: 1,
      single_use: true,
      starts_at: Time.zone.now,
      expires_at: 1.year.since,
      sellable_type: 'All'
    )
  end

  def self.generate_seven_eleven_reward
    CouponValue.create!(
      storefront_id: Storefront::MINIBAR_ID, # this method should only be called for Minibar
      active: true,
      generated: true,
      code: generate_code,
      description: '7-Eleven Reward',
      amount: 7.11,
      minimum_value: 0,
      combine: true,
      quota: 1,
      single_use: true,
      starts_at: Time.zone.now,
      expires_at: 1.month.since,
      sellable_type: 'All'
    )
  end

  private

  def coupon_amount(order)
    calculate_shipping_and_delivery_amount(amount, order)
  end
end
