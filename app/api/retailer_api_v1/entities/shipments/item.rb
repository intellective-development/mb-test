# frozen_string_literal: true

# Retailer shipments item entity
class RetailerAPIV1::Entities::Shipments::Item < Grape::Entity
  format_with(:price_formatter) { |value| (value * 100).to_i }

  expose :name, &:product_name
  expose :quantity
  expose :price, as: :unitPrice, format_with: :price_formatter
end
