module Dashboard
  module Integration
    module Specs
      module Builder
        class DeliveryBuilder
          attr_reader :delivery

          def self.build(existing_delivery = nil)
            builder = new(existing_delivery)
            yield(builder)
            builder.delivery
          end

          def initialize(existing_delivery = nil)
            if existing_delivery.nil?
              @delivery = Dashboard::Integration::Specs::Models::Delivery.new
              @delivery.order_special_instructions = ''
            else
              raise 'CustomerDetailsBuilder can be only initialized with nil or valid Delivery instance' unless existing_delivery.instance_of?(Dashboard::Integration::Specs::Models::Delivery)

              @delivery = existing_delivery
            end
          end

          def set_shipping_details(shipping_details)
            raise 'OrderBuilder::set_shipping_details must be provided with an valid CustomerDetails instance' unless shipping_details.instance_of?(Dashboard::Integration::Specs::Models::CustomerDetails)

            @delivery.shipping_details = shipping_details
          end

          def set_order_special_instructions(instructions)
            @delivery.order_special_instructions = instructions
          end
        end
      end
    end
  end
end
