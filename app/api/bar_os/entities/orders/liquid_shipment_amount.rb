# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidShipmentAmount
      class LiquidShipmentAmount < LiquidBase
        expose :sub_total, format_with: :float_string
        expose :taxed_amount, format_with: :float_string
        expose :coupon_amount, format_with: :float_string
        expose :shipping_charges, format_with: :float_string
        expose :tip_amount, format_with: :float_string
        expose :deals_total, format_with: :float_string
        expose :discounts_total, format_with: :float_string
        expose :taxed_total, format_with: :float_string
        expose :total_before_discounts, format_with: :float_string
        expose :bottle_deposits, format_with: :float_string
        expose :order_items_tax, format_with: :float_string
        expose :order_items_total, format_with: :float_string
        expose :shipping_tax, format_with: :float_string
        expose :total_before_coupon_applied, format_with: :float_string
        expose :shoprunner_total, format_with: :float_string
        expose :gift_card_amount, format_with: :float_string
        expose :additional_tax_amount, format_with: :float_string
        expose :bag_fee, format_with: :float_string
        expose :engraving_fee, format_with: :float_string
        expose :engraving_fee_discounts, format_with: :float_string
        expose :engraving_fee_after_discounts, format_with: :float_string
        expose :delivery_fee_discounts_total, format_with: :float_string
        expose :shipping_fee_discounts_total, format_with: :float_string
        expose :retail_delivery_fee, format_with: :float_string
        expose :membership_discount, format_with: :float_string
        expose :fulfillment_fee, format_with: :float_string
        expose :membership_shipping_discount, format_with: :float_string
        expose :membership_delivery_discount, format_with: :float_string
      end
    end
  end
end
