# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::ShipmentAmount
    class ShipmentAmount < Grape::Entity
      format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

      expose :sub_total, format_with: :price_formatter
      expose :taxed_amount, format_with: :price_formatter
      expose :shipping_charges, format_with: :price_formatter
      expose :tip_amount, format_with: :price_formatter
      expose :discounts_total, format_with: :price_formatter
      expose :taxed_total, format_with: :price_formatter
      expose :total_before_discounts, format_with: :price_formatter
      expose :bottle_deposits, format_with: :price_formatter
      expose :order_items_tax, format_with: :price_formatter
      expose :order_items_total, format_with: :price_formatter
      expose :shipping_tax, format_with: :price_formatter
      expose :bag_fee, format_with: :price_formatter
      expose :engraving_fee, format_with: :price_formatter
    end
  end
end
