# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Builders
        # ItemBuilder is a class that implements the ItemBuilderInterface for ShipStation Integrations
        class ItemBuilder
          include Dashboard::Integration::ShipStation::Models
          attr_reader :item

          def self.build
            builder = new
            yield(builder)
            builder.item
          end

          def initialize
            @item = Item.new
          end

          def with_sku(sku)
            @item.sku = sku
          end

          def with_quantity(quantity)
            @item.qty = quantity
          end

          def with_name(name)
            @item.name = name
          end

          def with_price(price)
            @item.price = price
          end

          def with_engraving(engraving)
            @item.engraving = engraving
          end
        end
      end
    end
  end
end
