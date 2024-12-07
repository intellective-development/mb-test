module Dashboard
  module Integration
    module ThreeJMS
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
              @order = Dashboard::Integration::ThreeJMS::Models::Order.new
            else
              raise 'OrderBuilder can be only initialized with nil or valid Order instance' unless existing_order.instance_of?(Dashboard::Integration::ThreeJMS::Models::Order)

              @order = existing_order
            end
          end

          def add_item(item)
            raise 'OrderBuilder::add_item must be provided with an valid Item instance' unless item.instance_of?(Dashboard::Integration::ThreeJMS::Models::Item)

            (@order.items ||= []) << item
          end

          def set_order_id(id)
            @order.id = id
          end

          def set_order_uuid(uuid)
            @order.order_uuid = uuid
          end

          def set_order_type(type)
            @order.order_type = type
          end

          def set_brand(brand)
            @order.brand = brand
          end

          def set_email(email)
            @order.email = email
          end

          def set_phone(phone)
            @order.phone = phone
          end

          def set_gift_detail(gift_detail)
            @order.gift_detail = gift_detail
          end

          def set_ship_to(address)
            raise 'OrderBuilder::set_ship_to must be provided with an valid Address instance' unless address.instance_of?(Dashboard::Integration::ThreeJMS::Models::Address)

            @order.ship_to = address
          end

          def set_qr_code(qr_code)
            @order.qr_code = qr_code
          end
        end
      end
    end
  end
end
