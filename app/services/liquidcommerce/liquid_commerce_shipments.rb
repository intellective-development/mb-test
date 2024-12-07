# frozen_string_literal: true

module LiquidCommerceShipments
  class ShipmentAttributes
    def initialize(order, shipment)
      @order = order
      @shipment = shipment
    end

    def build_amount_attributes(fulfillment)
      shipping_amounts = LiquidCommerceCoupons::ShipmentCalculator.new(
        @order,
        @shipment
      ).calculate_shipping_amounts(fulfillment)

      details = fulfillment[:details] || {}
      taxes = details[:taxes] || {}

      test = {
        sub_total: convert_to_dollars(fulfillment[:subtotal]),                # 149.97
        taxed_amount: convert_to_dollars(fulfillment[:tax]),                 # 14.88
        taxed_total: convert_to_dollars(fulfillment[:total]),                # 170.85
        shipping_charges: shipping_amounts[:total_fulfillment],       # 15.99 (original before discount)
        fulfillment_fee: shipping_amounts[:total_fulfillment],         # 15.99 (original before discount)
        shipping_tax: shipping_amounts[:total_tax],
        # shipping_fee_discounts_total: 0.0,   # 9.99
        # delivery_fee_discounts_total: 0.0,   # 0.00
        coupon_amount: convert_to_dollars(fulfillment[:discounts]),
        discounts_total: convert_to_dollars(fulfillment[:discounts]),
        # total_before_discounts: convert_to_dollars(fulfillment[:total] + fulfillment[:discounts]),                        # Original totals before any discounts
        # total_before_coupon_applied: convert_to_dollars(fulfillment[:total] + fulfillment[:discounts]),      # After discounts
        order_items_total: convert_to_dollars(fulfillment[:subtotal]),       # 149.97
        order_items_tax: convert_to_dollars(taxes[:products]),               # 13.31
        bottle_deposits: convert_to_dollars(taxes[:bottleDeposits]),         # 0.15
        bag_fee: convert_to_dollars(taxes[:bag]),                           # 0.00
        engraving_fee: convert_to_dollars(fulfillment[:engraving]),         # 0.00
        # engraving_fee_discounts: convert_to_dollars(details[:discounts][:engraving]), # 0.00
        # engraving_fee_after_discounts: 0.0,                                                                   # 0.00
        gift_card_amount: convert_to_dollars(fulfillment[:giftCards]),      # 0.00
        retail_delivery_fee: convert_to_dollars(taxes[:retailDelivery])     # 0.00
      }

      test
    end

    private

    def convert_to_dollars(cents)
      (cents || 0).to_f / 100.0
    end

    def calculate_engraving_after_discounts(engraving, discounts)
      ((engraving.to_i - discounts.to_i) / 100.0).round(2)
    end

  end
end