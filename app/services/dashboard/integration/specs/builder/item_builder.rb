module Dashboard
  module Integration
    module Specs
      module Builder
        class ItemBuilder
          attr_reader :item

          def self.build
            builder = new
            yield(builder)
            builder.item
          end

          def initialize
            @item = Dashboard::Integration::Specs::Models::Item.new
            @item.tax_exempt = false
          end

          def set_sku(sku)
            @item.primary_upc = sku
          end

          def set_name(name)
            @item.name = name
          end

          def set_price(price)
            @item.price = price.to_f
          end

          def set_quantity(quantity)
            @item.qty = quantity
          end

          def mark_as_tax_exempt
            @item.tax_exempt = true
          end
        end
      end
    end
  end
end
