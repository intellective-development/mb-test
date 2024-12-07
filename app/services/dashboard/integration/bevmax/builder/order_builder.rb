module Dashboard
  module Integration
    module Bevmax
      module Builder
        class OrderBuilder
          attr_reader :order

          def self.build(existing_order = nil)
            builder = new(existing_order)
            yield(builder)
            builder.order
          end

          def initialize(existing_order = nil)
            if existing_order.nil?
              @order = Dashboard::Integration::Bevmax::Models::Order.new
            else
              raise 'OrderBuilder can be only initialized with nil or valid Order instance' unless existing_order.instance_of?(Dashboard::Integration::Bevmax::Models::Order)

              @order = existing_order
            end
          end

          def set_business(business)
            raise 'OrderBuilder::set_business must be provided with a valid business model' unless business.is_a?(Business)

            @order.business = business
          end

          def set_store_number(store_number)
            @order.store_number = store_number
          end

          def add_item(item)
            raise 'OrderBuilder::add_item must be provided with an valid Item instance' unless item.instance_of?(Dashboard::Integration::Bevmax::Models::Item)

            (@order.items ||= []) << item
          end

          def set_order_id(id)
            @order.id = id
          end

          def set_tip(tip)
            @order.tip = tip.to_f
          end

          def set_order_number(order_number)
            @order.order_reference_number = order_number
          end

          def set_total_tax(tax)
            @order.total_tax = tax
          end

          def set_shipping_cost(cost)
            @order.shipping_cost = cost
          end

          def set_total_discount(discount)
            @order.total_discount = discount
          end

          def set_total_amount(amount)
            @order.total_amount = amount
          end

          def set_delivery_notes(notes)
            @order.delivery_notes = notes
          end

          def set_gift_detail(gift_detail)
            @order.gift_detail = gift_detail
          end

          def set_ship_to(address)
            raise 'OrderBuilder::set_ship_to must be provided with an valid Address instance' unless address.instance_of?(Dashboard::Integration::Bevmax::Models::Address)

            @order.ship_to = address
          end

          def set_bill_to(address)
            raise 'OrderBuilder::set_bill_to must be provided with an valid Address instance' unless address.instance_of?(Dashboard::Integration::Bevmax::Models::Address)

            @order.bill_to = address
          end
        end
      end
    end
  end
end
