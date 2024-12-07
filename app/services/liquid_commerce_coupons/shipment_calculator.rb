# frozen_string_literal: true

module LiquidCommerceCoupons
  class ShipmentCalculator
    def initialize(order, shipment)
      @order = order
      @shipment = shipment
      @coupon = order.coupon
    end

    def calculate_shipping_amounts(fulfillment)
      details = fulfillment[:details] || {}
      taxes = details[:taxes] || {}

      shipping = convert_to_dollars(fulfillment[:shipping])
      delivery = convert_to_dollars(fulfillment[:delivery])
      total_fulfillment = convert_to_dollars(fulfillment[:delivery] + fulfillment[:shipping])

      # Calculate base discounts
      if @coupon && (@coupon.free_shipping || @coupon.free_delivery)
        discount_amounts = calculate_free_shipping_delivery_discounts(
          shipping,
          delivery,
          @coupon.maximum_value
        )
      else
        discount_amounts = calculate_standard_discounts(details[:discounts] || {})
      end

      # Calculate tax adjustments
      tax_adjustments = calculate_tax_adjustments(taxes)

      {
        original_shipping: shipping,
        original_delivery: delivery,
        total_fulfillment: total_fulfillment,
        shipping_discount: discount_amounts[:shipping_discount],
        delivery_discount: discount_amounts[:delivery_discount],
        effective_shipping: [shipping - discount_amounts[:shipping_discount], 0].max,
        effective_delivery: [delivery - discount_amounts[:delivery_discount], 0].max,
        shipping_tax: tax_adjustments[:shipping_tax],
        delivery_tax: tax_adjustments[:delivery_tax],
        total_tax: tax_adjustments[:total_tax],
        retail_fee: taxes[:retailDelivery],
      }
    end

    private

    def calculate_free_shipping_delivery_discounts(shipping, delivery, maximum_value)
      max_discount = maximum_value || Float::INFINITY

      if @coupon.free_shipping
        shipping_discount = [shipping, max_discount].min
        remaining_discount = [max_discount - shipping_discount, 0].max

        delivery_discount = if @coupon.free_delivery
                              [delivery, remaining_discount].min
                            else
                              0
                            end
      else
        delivery_discount = [delivery, max_discount].min
        shipping_discount = 0
      end

      {
        shipping_discount: shipping_discount,
        delivery_discount: delivery_discount
      }
    end

    def calculate_standard_discounts(discounts)
      {
        shipping_discount: convert_to_dollars(discounts[:shipping]),
        delivery_discount: convert_to_dollars(discounts[:delivery])
      }
    end

    def calculate_tax_adjustments(taxes)
      {
        shipping_tax: convert_to_dollars(taxes[:shipping]), # 1.42
        delivery_tax: convert_to_dollars(taxes[:delivery]), # 0.00
        total_tax: convert_to_dollars(taxes[:shipping]) +
          convert_to_dollars(taxes[:delivery]) +
          convert_to_dollars(taxes[:retailDelivery]) # 1.42 + 0 + 0 = 1.42
      }
    end

    def convert_to_dollars(cents)
      (cents || 0).to_f / 100.0
    end
  end
end