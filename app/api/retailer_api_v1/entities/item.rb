# frozen_string_literal: true

# Retailer item entity
class RetailerAPIV1::Entities::Item < Grape::Entity
  format_with(:price_formatter) { |value| (value * 100).to_i }

  expose :name, &:product_name
  expose :volume do |item|
    item.product.item_volume
  end
  expose :upc do |item|
    item.product.upc
  end
  expose :category do |item|
    item.product.hierarchy_category_name
  end
  expose :msku do |item|
    item.variant.sku
  end
  expose :quantity
  expose :price, as: :unitPrice, format_with: :price_formatter
  expose :images do |item|
    item.product.image_urls
  end
  expose :engraving do
    expose :engraving?, as: :hasEngraving
    expose :lines do |item|
      [item.item_options&.line1, item.item_options&.line2, item.item_options&.line3, item.item_options&.line4].compact
    end
  end
end
