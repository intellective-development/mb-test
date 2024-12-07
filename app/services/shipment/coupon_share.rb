class Shipment::CouponShare
  attr_reader :shipment

  def initialize(shipment)
    @shipment = shipment
  end

  def call
    return 0 if shipment.digital? # Coupons cant be used on gift card purchases TECH-3110

    promo_coupons = all_coupons.select(&:promo_coupon?)
    gift_cards = all_coupons.select(&:gift_card_coupon?)

    (promo_coupons + gift_cards).sum do |coupon|
      discount_amount_on_order = calculate_coupon_value(coupon)
      Coupons::ShipmentShare.new(coupon, shipment, discount_amount_on_order).call
    end
  end

  private

  def calculate_coupon_value(coupon)
    coupon.gift_card_coupon? && coupon.balance_for_order?(order) ? coupon.balance_for_order(order) : coupon.value(order)
  end

  def all_coupons
    @all_coupons ||= order.all_coupons
  end

  def order
    @order ||= shipment.order
  end
end
