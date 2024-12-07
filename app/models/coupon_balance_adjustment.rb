# == Schema Information
#
# Table name: coupon_balance_adjustments
#
#  id         :integer          not null, primary key
#  amount     :float            default(0.0)
#  debit      :boolean          default(TRUE), not null
#  reason     :integer          default("applied_to_order")
#  coupon_id  :integer
#  created_at :datetime
#  updated_at :datetime
#  order_id   :integer
#
# Indexes
#
#  coupon_balance_adjustments_order_id_idx        (order_id)
#  index_coupon_balance_adjustments_on_coupon_id  (coupon_id)
#

class CouponBalanceAdjustment < ActiveRecord::Base
  enum reason: {
    applied_to_order: 0,
    refunded: 1,
    customer_service_adjustment: 2
  }

  belongs_to :coupon, inverse_of: :coupon_balance_adjustments, class_name: 'CouponDecreasingBalance'
  belongs_to :order

  #----------------------------
  # Scopes
  #----------------------------
  scope :debit, -> { where(debit: true) }
  scope :credit, -> { where(debit: false) }
end
