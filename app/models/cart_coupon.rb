# frozen_string_literal: true

# == Schema Information
#
# Table name: cart_coupons
#
#  cart_id   :bigint(8)        not null
#  coupon_id :bigint(8)        not null
#
# Indexes
#
#  index_cart_coupons_on_cart_id                (cart_id)
#  index_cart_coupons_on_cart_id_and_coupon_id  (cart_id,coupon_id) UNIQUE
#  index_cart_coupons_on_coupon_id              (coupon_id)
#
class CartCoupon < ApplicationRecord
  belongs_to :cart
  belongs_to :coupon

  validates :cart_id, presence: true
  validates :coupon_id, presence: true
  validate :coupon, -> { errors.add(:coupon_id, 'is not a gift card') unless coupon.type == 'CouponDecreasingBalance' }
end
