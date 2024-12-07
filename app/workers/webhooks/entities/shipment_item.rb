# frozen_string_literal: true

module Webhooks
  module Entities
    # Webhooks::Entities::ShipmentItem
    class ShipmentItem < Grape::Entity
      format_with(:price_formatter) { |value| (value * 100).to_i }

      expose :name do |item|
        item.variant&.name
      end
      expose :volume do |item|
        item.variant&.item_volume
      end
      expose :upc do |item|
        item.product&.upc
      end
      expose :category do |item|
        item.product&.hierarchy_category_name
      end
      expose :msku do |item|
        item.variant&.sku
      end
      expose :price, as: :unitPrice, format_with: :price_formatter
      expose :quantity
      expose :images do |item|
        image = item.product&.product_trait&.main_image_url.presence || item.variant&.featured_image
        image.present? ? [image] : []
      end
      expose :engraving do |item|
        has_engraving = (item.item_options.instance_of? EngravingOptions)
        lines = []
        if has_engraving
          lines << item.item_options.line1 if item.item_options.line1.present?
          lines << item.item_options.line2 if item.item_options.line2.present?
          lines << item.item_options.line3 if item.item_options.line3.present?
          lines << item.item_options.line4 if item.item_options.line4.present?
        end
        {
          hasEngraving: (item.item_options.instance_of? EngravingOptions),
          lines: lines
        }
      end
    end
  end
end
