# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::GiftCardOptions
    class GiftCardOptions < Grape::Entity
      expose :type, proc: lambda { |_instance, _options|
        Variant.options_types[:gift_card]
      }

      format_with(:iso_timestamp) { |dt| dt&.iso8601 }

      expose :sender
      expose :message
      expose :recipients
      expose :send_date, format_with: :iso_timestamp
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
  end
end
