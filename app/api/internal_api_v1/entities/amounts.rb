# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::Amounts
    class Amounts < Grape::Entity
      format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

      expose :sales_tax,           as: :tax,       format_with: :price_formatter
      expose :total_taxed_amount,  as: :tax_total, format_with: :price_formatter
      expose :tip_amount,          as: :tip,       format_with: :price_formatter, if: ->(instance, _options) { instance.shipping_methods.where(allows_tipping: true).exists? }
      expose :taxed_total,         as: :total, format_with: :price_formatter
      expose :discounts_total, as: :coupon, format_with: :price_formatter
      expose :shipping_after_discounts, format_with: :price_formatter
      expose :delivery_after_discounts, format_with: :price_formatter
      expose :service_fee,                     format_with: :price_formatter
      expose :engraving_fee,                   format_with: :price_formatter
      expose :membership_discount, format_with: :price_formatter
      expose :membership_price, format_with: :price_formatter
      expose :membership_service_fee_discount, format_with: :price_formatter
      expose :membership_engraving_fee_discount, format_with: :price_formatter
      expose :membership_shipping_discount, format_with: :price_formatter
      expose :membership_on_demand_discount, format_with: :price_formatter

      def delivery_charges
        object.amounts&.delivery_charges
      end

      def coupon_amount
        current_coupon_amount = object.amounts.coupon_amount
        current_coupon_amount -= object.amounts.delivery_charges[:shipping] if object.free_shipping_coupon?
        current_coupon_amount -= object.amounts.delivery_charges[:on_demand] if object.free_delivery_coupon?

        current_coupon_amount.negative? ? 0.0 : current_coupon_amount.to_f.round_at(2)
      end
    end
  end
end
