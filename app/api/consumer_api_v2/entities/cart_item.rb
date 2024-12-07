class ConsumerAPIV2::Entities::CartItem < Grape::Entity
  format_with(:float, &:to_f)

  expose :identifier do |item|
    item.identifier.to_i
  end

  expose :quantity
  expose :product do |item|
    ProductGroupingVariantStoreView::Entity.represent(item.variant&.product_grouping_variant_store_view, business: item.cart.storefront.business)
  end
  expose :product_grouping do |item|
    item.variant&.product_size_grouping&.get_entity(item.cart.storefront.business, item.variant.product, [item.variant&.supplier_id])
  end

  expose :item_options do |item|
    value = item.item_options
    if value.instance_of? EngravingOptions
      ConsumerAPIV2::Entities::EngravingOption.represent(value, options)
    else
      gift_card_image_fallback = item.variant&.product_size_grouping&.gift_card_theme
      ConsumerAPIV2::Entities::GiftCardOptions.represent(value, gift_card_image_fallback: gift_card_image_fallback)
    end
  end

  expose :bundle
  def bundle
    ConsumerAPIV2::Entities::Bundle.represent(options[:bundle], options)
  end

  expose :product_bundle do |item|
    ConsumerAPIV2::Entities::ProductBundle.represent(item.product_bundle, options)
  end

  expose :customer_placement
  expose :supplier_name
  expose :delivery_method
  expose :delivery_expectation
  expose :engraving_configs do
    expose :active, documentation: { type: 'boolean', desc: 'Engraving.' } do |_|
      object.cart.storefront.enable_engravings && ActiveModel::Type::Boolean.new.cast(product_trait&.engravable?)
    end
    expose :characters, documentation: { type: 'integer', desc: 'Characters.' } do |_|
      product_trait&.engraving_lines_character_limit.to_i
    end
    expose :lines, documentation: { type: 'integer', desc: 'Lines.' } do |_|
      product_trait&.engraving_lines.to_i
    end
    expose :location, documentation: { type: 'array[string]', desc: 'Location.' } do |_|
      Array.wrap(product_trait&.engraving_location_options)
    end
  end

  def delivery_method
    shipping_method&.shipping_type
  end

  def delivery_expectation
    shipping_method&.delivery_expectation
  end

  def shipping_method
    supplier = object.supplier
    default = supplier.default_shipping_method

    return @shipping_method ||= default if options[:address].blank?

    @shipping_method ||= supplier.shipping_methods.find { |sm| sm.covers_address?(options[:address]) } || default
  end

  def product_trait
    object.variant&.product&.product_trait
  end
end
