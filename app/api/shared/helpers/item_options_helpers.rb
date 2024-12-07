module Shared::Helpers::ItemOptionsHelpers
  extend Grape::API::Helpers

  params :item_options_params do
    optional :options, default: {}, type: Hash, desc: 'Hash of options for giftcards', coerce_with: lambda { |options|
      options.keys.present? ? options.reverse_merge!({ type: GiftCardOptions.name }) : options
    } do
      optional :type, type: String, coerce_with: lambda { |type|
        if type.to_s == '2'
          EngravingOptions.name
        else
          GiftCardOptions.name
        end
      }
      given type: ->(type) { type == GiftCardOptions.name } do
        use :gift_card_options
      end
      given type: ->(type) { type == EngravingOptions.name } do
        use :engraving_options
      end
    end
  end

  params :gift_card_options do
    requires :sender,             type: String
    optional :message,            type: String
    requires :recipients,         type: Array, coerce_with: ->(arr) { arr.compact.map(&:downcase) }
    optional :send_date,          type: Date
    optional :price,              type: Float
    optional :gift_card_image_id, type: Integer
  end

  params :engraving_options do
    optional :line1,             type: String
    optional :line2,             type: String
    optional :line3,             type: String
    optional :line4,             type: String
  end
end
