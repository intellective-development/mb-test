class ConsumerAPIV2::Entities::OrderItem < Grape::Entity
  format_with(:float, &:to_f)

  expose :id do |item|
    item[0]
  end
  expose :variant_id do |item|
    item[1].first.variant_id
  end
  expose :price, format_with: :float do |item|
    item[1].first.price
  end
  expose :total do |item|
    item[1].sum(&:total)
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
  expose :delivery_method_id do |item|
    item[1].first.shipment.shipping_method_id
  end
  expose :delivery_method_type do |item|
    item[1].first.shipment.shipping_type
  end
  expose :delivery_method_delivery_expectation do |item|
    item[1].first.shipment.shipping_method&.delivery_expectation
  end
  expose :scheduled_for do |item|
    timezone = item[1].first.supplier ? ActiveSupport::TimeZone::MAPPING.key(item[1].first.supplier.timezone) : 'Eastern Time (US & Canada)'
    item[1].first.shipment.scheduled_for&.in_time_zone(timezone)&.iso8601
  end
  expose :supplier_id do |item|
    item[1].first.supplier_id
  end
  expose :product_id do |item|
    item[1].first.variant&.product&.permalink
  end
  expose :image_url do |item|
    item[1].first.product&.product_trait&.main_image_url.presence || item[1].first.variant&.featured_image
  end
  expose :item_options do |item|
    value = item[1].first.item_options
    if value.instance_of? EngravingOptions
      ConsumerAPIV2::Entities::EngravingOption.represent(value, options)
    else
      gift_card_image_fallback = item[1].first.variant.product_size_grouping.gift_card_theme
      ConsumerAPIV2::Entities::GiftCardOptions.represent(value, gift_card_image_fallback: gift_card_image_fallback)
    end
  end
  expose :product_bundle do |item|
    ConsumerAPIV2::Entities::ProductBundle.represent(item[1].first.product_bundle, options)
  end
  expose :engraving, if: ->(item) { item[1].first.product&.product_trait&.engravable? } do |item|
    product_trait = item[1].first.product&.product_trait
    ConsumerAPIV2::Entities::ProductTraits::Engraving.represent(product_trait)
  end
end
