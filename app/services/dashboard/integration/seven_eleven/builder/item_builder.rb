module Dashboard
  module Integration
    module SevenEleven
      module Builder
        class ItemBuilder
          attr_reader :item

          def self.build
            builder = new
            yield(builder)
            builder.item
          end

          def initialize
            @item = Dashboard::Integration::SevenEleven::Models::Item.new
          end

          def set_sku(sku)
            @item.item_id = sku
          end

          def set_price(price)
            @item.price = (price * 100).to_i
          end

          def set_quantity(quantity)
            @item.qty = quantity
          end

          def set_name(name)
            @item.name = name
          end
        end
      end
    end
  end
end
