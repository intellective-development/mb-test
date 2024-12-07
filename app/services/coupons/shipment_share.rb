module Coupons
  class ShipmentShare
    attr_reader :coupon, :shipment, :order_coupons_values

    def initialize(coupon, shipment, order_coupons_values)
      @coupon = coupon
      @shipment = shipment
      @order_coupons_values = order_coupons_values
    end

    def call
      coupon_share_amount = coupon_share_amount_calculation

      coupon_share_calculation(coupon, coupon_share_amount)
    end

    private

    def coupon_share_amount_calculation
      return order_coupon_value if order_coupons_values <= order.coupon_amount_share

      order_coupon_value - (order_coupons_values - order.coupon_amount_share)
    end

    def coupon_share_calculation(coupon, coupon_share_amount)
      Rails.logger.info("[COUPON_DEBUG] Starting calculation - amount: #{coupon_share_amount}, liquidcommerce: #{shipment.liquidcommerce?}")

      return 0.0 if coupon_share_amount.zero?

      order_total = order.without_digital_total_before_coupon_applied - order.membership_price
      limit = shipment.total_before_deals
      shipment_total = shipment.total_before_deals

      # Original logic remains unchanged for all other cases
      coupon_share_amount -= order_shipping_amount if free_shipping_charges? && shipment_amount_present?

      if coupon.promo_coupon? || order.free_shipping_or_delivery_coupon? || free_shipping_charges? && shipment_amount_present?
        limit -= shipment_shipping_amount
        shipment_total -= shipment_shipping_amount
        order_total -= order_shipping_amount
      end

      if coupon.promo_coupon?
        limit -= shipment.tax_total
        shipment_total -= shipment_taxes
        order_total -= order.amounts_without_digital_shipments.taxed_amount + order.tip_amount
      end

      coupon_share = ValueSplitter
                       .new(coupon_share_amount, limit: limit)
                       .split(order_total, shipment_total)

      coupon_share += shipment.delivery_fee if free_shipping_charges? && shipment_amount_present?
      coupon_share
    end
    def shipment_amount_present?
      shipment.shipment_amount.present?
    end

    def free_shipping_charges?
      coupon.free_delivery? || coupon.free_shipping?
    end

    def shipment_taxes
      @shipment_taxes ||= shipment.tax_total_with_bottle_deposits_and_bag_fees + shipment.tip_share
    end

    def order_coupon_value
      @order_coupon_value ||= coupon.gift_card_coupon? && coupon.balance_for_order?(order) ? coupon.balance_for_order(order) : coupon.value(order)
    end

    def shipment_shipping_amount
      @shipment_shipping_amount ||= shipment.delivery_fee
    end

    def order_shipping_amount
      @order_shipping_amount ||= order.shipping_charges
    end

    def order
      @order ||= shipment.order
    end
  end
end
