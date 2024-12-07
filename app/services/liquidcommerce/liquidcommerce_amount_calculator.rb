# frozen_string_literal: true

module LiquidcommerceAmountCalculator
  class << self
    def calculate_core_amounts(amounts, details = {})
      Rails.logger.info("[LIQUID_COMMERCE] Calculating core amounts")

      taxes = details[:taxes] || {}
      discounts = details[:discounts] || {}

      {
        sub_total: convert_to_dollars(amounts[:subtotal]),
        shipping_charges: convert_to_dollars(amounts[:shipping] + amounts[:delivery]),
        taxed_amount: convert_to_dollars(amounts[:tax]),
        taxed_total: convert_to_dollars(amounts[:total]),
        order_items_tax: convert_to_dollars(taxes[:products]),
        order_items_total: convert_to_dollars(amounts[:subtotal]),
        shipping_tax: calculate_shipping_tax(taxes),
        gift_card_amount: convert_to_dollars(amounts[:giftCards]),
        service_fee: convert_to_dollars(amounts[:platform]),
        bag_fee: convert_to_dollars(taxes[:bag]),
        engraving_fee: convert_to_dollars(amounts[:engraving]),
        retail_delivery_fee: convert_to_dollars(taxes[:retailDelivery]),
        bottle_deposits: convert_to_dollars(taxes[:bottleDeposits]),
        discounts_total: convert_to_dollars(amounts[:discounts]),
        tip_amount: convert_to_dollars(amounts[:tip]),
        total_before_coupon_applied: convert_to_dollars(amounts[:total].to_i + amounts[:discounts].to_i)
      }
    end

    private

    def calculate_shipping_tax(taxes)
      (
        taxes[:shipping].to_i +
          taxes[:delivery].to_i +
          taxes[:retailDelivery].to_i
      ).to_f / 100.0
    end

    def convert_to_dollars(cents)
      (cents || 0).to_f / 100.0
    end
  end
end