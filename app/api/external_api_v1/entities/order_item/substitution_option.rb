# frozen_string_literal: true

class ExternalAPIV1
  module Entities
    class OrderItem
      # ExternalAPIV1::Entities::OrderItem::SubstitutionOption
      class SubstitutionOption < Grape::Entity
        format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

        expose :sku
        expose :product_display_name, as: :product_name
        expose :type
        expose :item_volume, as: :volume
        expose :count_on_hand, as: :inventory
        expose :price, format_with: :price_formatter

        private

        def type
          object.product.hierarchy_category_name
        end
      end
    end
  end
end
