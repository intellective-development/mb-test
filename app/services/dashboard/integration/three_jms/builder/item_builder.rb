module Dashboard
  module Integration
    module ThreeJMS
      module Builder
        class ItemBuilder
          attr_reader :item

          def self.build
            builder = new
            yield(builder)
            builder.item
          end

          def initialize
            @item = Dashboard::Integration::ThreeJMS::Models::Item.new
          end

          def set_sku(sku)
            @item.sku = sku
          end

          def set_quantity(quantity)
            @item.qty = quantity
          end

          def set_name(name)
            @item.name = name
          end

          def set_engraving(engraving)
            @item.engraving = engraving
          end

          def set_price(price)
            @item.price = price
          end
        end
      end
    end
  end
end
