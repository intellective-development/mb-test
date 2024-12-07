# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Builders
        # OrderBuilder is a class that implements the OrderBuilderInterface for ShipStation Integrations
        class OrderBuilder
          include Dashboard::Integration::ShipStation::Models
          attr_reader :order

          def self.build(existing_order = nil)
            builder = new(existing_order)
            yield(builder)
            builder.order
          end

          def initialize(existing_order = nil)
            if existing_order.nil?
              @order = Order.new
            else
              raise 'OrderBuilder can be only initialized with nil or valid Order instance' unless existing_order.instance_of?(Order)

              @order = existing_order
            end
          end

          def add_item(item)
            raise 'OrderBuilder::add_item must be provided with an valid Item instance' unless item.instance_of?(Item)

            (@order.items ||= []) << item
          end

          def with_order_id(id)
            @order.id = id
          end

          def with_order_number(uuid)
            @order.order_number = uuid
          end

          def with_order_date(date)
            @order.order_date = date
          end

          def with_gift_detail(gift_detail)
            @order.gift_detail = gift_detail
          end

          def with_delivery_notes(delivery_notes)
            @order.delivery_notes = delivery_notes
          end

          def with_total_amount(total_amount)
            @order.total_amount = total_amount
          end

          def with_shipping_fee(shipping_fee)
            @order.shipping_fee = shipping_fee
          end

          def with_tax_amount(tax_amount)
            @order.tax_amount = tax_amount
          end

          def with_store_id(store_id)
            @order.store_id = store_id
          end

          def with_ship_to(address)
            raise 'OrderBuilder::with_ship_to must be provided with an valid Address instance' unless address.instance_of?(Address)

            @order.ship_to = address
          end

          def with_bill_to(address)
            raise 'OrderBuilder::with_bill_to must be provided with an valid Address instance' unless address.instance_of?(Address)

            @order.bill_to = address
          end

          def with_storefront_name(storefront_name)
            @order.storefront_name = storefront_name
          end
        end
      end
    end
  end
end
