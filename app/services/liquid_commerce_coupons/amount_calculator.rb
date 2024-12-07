# frozen_string_literal: true

module LiquidCommerceCoupons
  class AmountCalculator
    def self.calculate_core_amounts(amounts, details = {}, order = nil)
      taxes = details[:taxes] || {}
      discounts = details[:discounts] || {}

      # Handle shipping components with coupon logic
      shipping_components = calculate_shipping_components(amounts, discounts, order)

      # Calculate totals
      total = convert_to_dollars(amounts[:total])
      total_discounts = convert_to_dollars(amounts[:discounts])
      total_before_coupon = convert_to_dollars(amounts[:total].to_i + amounts[:discounts].to_i)

      test = {
        sub_total: convert_to_dollars(amounts[:subtotal]),
        taxed_total: total,
        shipping_charges: shipping_components[:original_charges],
        # shipping_after_discounts: shipping_components[:after_discounts],
        # delivery_after_discounts: shipping_components[:delivery_after_discounts],
        taxed_amount: convert_to_dollars(amounts[:tax]),
        # coupon_amount: total_discounts,
        tip_amount: convert_to_dollars(amounts[:tip]),
        total_before_discounts: total_before_coupon,
        bottle_deposits: convert_to_dollars(taxes[:bottleDeposits]),
        order_items_tax: convert_to_dollars(taxes[:products]),
        order_items_total: convert_to_dollars(amounts[:subtotal]),
        shipping_tax: shipping_components[:tax],
        # deals_total: 0.0,
        discounts_total: total_discounts,
        total_before_coupon_applied: total_before_coupon,
        # shoprunner_total: 0.0,
        # tip_eligible_amount: 0.0,
        # additional_tax: 0.0,
        gift_card_amount: convert_to_dollars(amounts[:giftCards]),
        service_fee: convert_to_dollars(amounts[:platform]),
        bag_fee: convert_to_dollars(taxes[:bag]),
        retail_delivery_fee: convert_to_dollars(taxes[:retailDelivery]),
        shipping_fee_discounts_total: shipping_components[:shipping_discount],
        delivery_fee_discounts_total: shipping_components[:delivery_discount],
        engraving_fee: convert_to_dollars(amounts[:engraving]),
        # engraving_fee_discounts: convert_to_dollars(details[:discounts][:engraving]),
        # engraving_fee_after_discounts: calculate_engraving_after_discounts(
        #   amounts[:engraving],
        #   details[:discounts][:engraving]
        # ),
        # membership_discount: 0.0,
        # membership_price: 0.0,
        # membership_tax: 0.0,
        # membership_service_fee_discount: 0.0,
        # membership_engraving_fee_discount: 0.0,
        # membership_shipping_discount: 0.0,
        # membership_on_demand_discount: 0.0,
        # fulfillment_fee: shipping_components[:original_charges]
      }

      test
    end

    private

    def self.calculate_shipping_components(amounts, discounts, order)
      original_shipping = convert_to_dollars(amounts[:shipping])
      original_delivery = convert_to_dollars(amounts[:delivery])
      original_charges = original_shipping + original_delivery

      if order&.coupon&.free_shipping_or_delivery_coupon?
        max_discount = order.coupon.maximum_value || Float::INFINITY

        shipping_discount = [original_shipping, max_discount].min
        remaining_discount = max_discount - shipping_discount
        delivery_discount = [original_delivery, remaining_discount].min

        effective_shipping = original_shipping - shipping_discount
        effective_delivery = original_delivery - delivery_discount
      else
        shipping_discount = convert_to_dollars(discounts[:shipping])
        delivery_discount = convert_to_dollars(discounts[:delivery])

        effective_shipping = original_shipping - shipping_discount
        effective_delivery = original_delivery - delivery_discount
      end

      {
        original_charges: original_charges,
        after_discounts: effective_shipping,
        delivery_after_discounts: effective_delivery,
        shipping_discount: shipping_discount,
        delivery_discount: delivery_discount,
        tax: calculate_adjusted_shipping_tax(
          amounts,
          shipping_discount,
          delivery_discount,
          original_shipping,
          original_delivery
        )
      }
    end

    def self.calculate_adjusted_shipping_tax(amounts, shipping_discount, delivery_discount, original_shipping, original_delivery)
      return 0.0 if original_shipping.zero? && original_delivery.zero?

      shipping_tax_ratio = shipping_discount.zero? ? 1 : (1 - (shipping_discount / original_shipping))
      delivery_tax_ratio = delivery_discount.zero? ? 1 : (1 - (delivery_discount / original_delivery))

      shipping_tax = convert_to_dollars(amounts.dig(:details, :taxes, :shipping))
      delivery_tax = convert_to_dollars(amounts.dig(:details, :taxes, :delivery))
      retail_delivery_tax = convert_to_dollars(amounts.dig(:details, :taxes, :retailDelivery))

      (shipping_tax * shipping_tax_ratio) +
        (delivery_tax * delivery_tax_ratio) +
        retail_delivery_tax
    end

    def self.calculate_engraving_after_discounts(engraving, discount)
      (engraving.to_i - discount.to_i).to_f / 100.0
    end

    def self.convert_to_dollars(cents)
      (cents || 0).to_f / 100.0
    end
  end
end