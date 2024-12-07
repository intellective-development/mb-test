# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::OrderItem
    class OrderItem < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt&.iso8601 }
      format_with(:float, &:to_f)

      expose :id do |item|
        item[0]
      end
      expose :price, format_with: :float do |item|
        item[1].first.price
      end
      expose :total do |item|
        item[1].sum(&:total)
      end
      expose :created_at, format_with: :iso_timestamp do |item|
        item[1].first.created_at
      end
      expose :updated_at, format_with: :iso_timestamp do |item|
        item[1].first.updated_at
      end
      expose :tax_charge, format_with: :float do |item|
        item[1].first.tax_charge
      end
      expose :bottle_deposits, format_with: :float do |item|
        item[1].first.bottle_deposits
      end

      expose :quantity do |item|
        item[1].sum(&:quantity)
      end
      expose :name do |item|
        item[1].first.variant&.name
      end
      expose :volume do |item|
        item[1].first.variant&.item_volume
      end
      expose :sku do |item|
        item[1].first.variant&.sku
      end
      expose :product_id do |item|
        item[1].first.variant&.product_id
      end

      expose :image_url do |item|
        item[1].first.product&.product_trait&.main_image_url.presence || item[1].first.variant&.featured_image
      end
      expose :engraving_location do |item|
        item[1].first.product&.product_trait&.engraving_location
      end
      expose :engraving_options, if: ->(instance, _options) { instance[1].first.item_options.instance_of? EngravingOptions } do |item|
        ConsumerAPIV2::Entities::EngravingOption.represent(item[1].first.item_options)
      end
      expose :gift_card_options, if: ->(instance, _options) { instance[1].first.item_options.instance_of? GiftCardOptions } do |item|
        gift_card_image_fallback = item[1].first.variant.product_size_grouping.gift_card_theme
        InternalAPIV1::Entities::GiftCardOptions.represent(item[1].first.item_options, gift_card_image_fallback: gift_card_image_fallback)
      end
      expose :product_bundle do |item|
        ConsumerAPIV2::Entities::ProductBundle.represent(item[1].first.product_bundle, options)
      end
    end
  end
end
