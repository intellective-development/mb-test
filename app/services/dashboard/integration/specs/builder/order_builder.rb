module Dashboard
  module Integration
    module Specs
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
              @order = Dashboard::Integration::Specs::Models::Order.new
            else
              raise 'OrderBuilder can be only initialized with nil or valid Order instance' unless existing_order.instance_of?(Dashboard::Integration::Specs::Models::Order)

              @order = existing_order
            end
          end

          def set_store_number(store_number)
            @order.store_number = store_number.to_i
          end

          def add_item(item)
            raise 'OrderBuilder::add_item must be provided with an valid Item instance' unless item.instance_of?(Dashboard::Integration::Specs::Models::Item)

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

          def set_fulfillment_time(fulfillment_time)
            @order.fulfillment_time = fulfillment_time
          end

          def set_customer_details(customer_details)
            raise 'OrderBuilder::set_customer_details must be provided with an valid CustomerDetails instance' unless customer_details.instance_of?(Dashboard::Integration::Specs::Models::CustomerDetails)

            @order.customer_details = customer_details
          end

          def set_summary(summary)
            raise 'OrderBuilder::set_summary must be provided with an valid OrderSummary instance' unless summary.instance_of?(Dashboard::Integration::Specs::Models::OrderSummary)

            @order.summary = summary
          end

          def set_delivery(delivery)
            raise 'OrderBuilder::set_delivery must be provided with an valid Delivery instance' unless delivery.instance_of?(Dashboard::Integration::Specs::Models::Delivery)

            @order.delivery = delivery
          end
        end
      end
    end
  end
end
