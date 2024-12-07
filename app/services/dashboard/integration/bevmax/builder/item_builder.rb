module Dashboard
  module Integration
    module Bevmax
      module Builder
        class ItemBuilder
          attr_reader :item

          def self.build
            builder = new
            yield(builder)
            builder.item
          end

          def initialize
            @item = Dashboard::Integration::Bevmax::Models::Item.new
            @item.tax_exempt = false
          end

          def set_sku(sku)
            @item.sku = sku
          end

          def set_price(price)
            @item.price = price.to_f
          end

          def set_quantity(quantity)
            @item.qty = quantity
          end

          def set_tax_exempt(tax)
            @item.tax_exempt = tax
          end

          def set_engraving(engraving)
            @item.engraving = engraving
          end
        end
      end
    end
  end
end
