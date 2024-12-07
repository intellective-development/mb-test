class ConsumerAPIV2::Entities::GiftCardOptions < Grape::Entity
  expose :type, proc: lambda { |_instance, _options|
    Variant.options_types[:gift_card]
  }

  expose :sender
  expose :message
  expose :recipients
  expose :send_date
  expose :price do |item_options|
    item_options.price.to_f.round(2)
  end
  expose :gift_card_image, with: ConsumerAPIV2::Entities::GiftCardImage do |gift_card_options, options|
    if gift_card_options.gift_card_image.present?
      gift_card_options.gift_card_image
    elsif options[:gift_card_image_fallback].present?
      {
        correlation_id: -1,
        image_url: options[:gift_card_image_fallback].theme_image_url,
        thumb_url: options[:gift_card_image_fallback].thumb_image_url
      }
    end
  end
end
