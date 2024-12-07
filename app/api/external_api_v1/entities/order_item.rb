class ExternalAPIV1::Entities::OrderItem < Grape::Entity
  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

  expose :id
  expose :variant_id

  expose :name do |order_item|
    order_item.variant&.name
  end

  expose :item_size do |order_item|
    order_item.variant&.item_volume
  end

  expose :sku do |order_item|
    order_item.variant&.sku
  end

  expose :price, format_with: :price_formatter
  expose :total, format_with: :price_formatter
  expose :quantity
end
