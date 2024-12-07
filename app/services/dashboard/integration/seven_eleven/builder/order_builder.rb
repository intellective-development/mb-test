module Dashboard
  module Integration
    module SevenEleven
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
              @order = Dashboard::Integration::SevenEleven::Models::Order.new
            else
              raise 'OrderBuilder can be only initialized with nil or valid Order instance' unless existing_order.instance_of?(Dashboard::Integration::SevenEleven::Models::Order)

              @order = existing_order
            end
          end

          def set_store_id(store_id)
            @order.store_id = store_id
          end

          def add_item(item)
            raise 'OrderBuilder::add_item must be provided with an valid Item instance' unless item.instance_of?(Dashboard::Integration::SevenEleven::Models::Item)

            (@order.items ||= []) << item
          end

          def add_fee_item(item)
            raise 'OrderBuilder::add_fee_item must be provided with an valid Item instance' unless item.instance_of?(Dashboard::Integration::SevenEleven::Models::Item)

            (@order.fee_items ||= []) << item
          end

          def mark_as_delivery
            @order.order_type = 'delivery'
          end

          def set_shipping_address(shipping)
            raise 'OrderBuilder::set_shipping_address must be provided with an valid Shipping instance' unless shipping.instance_of?(Dashboard::Integration::SevenEleven::Models::Shipping)

            @order.shipping = shipping
          end

          def set_delivery_note(note)
            raise 'No shipping address defined. Use OrderBuilder::set_shipping_address before OrderBuilder::set_delivery_note' if @order.shipping.nil?

            @order.shipping = ShippingBuilder.build(@order.shipping) do |b|
              b.set_delivery_note(note)
            end
          end

          def set_payment_details(payment_details)
            raise 'OrderBuilder::set_payment_details must be provided with an valid PaymentDetails instance' unless payment_details.instance_of?(Dashboard::Integration::SevenEleven::Models::PaymentDetails)

            @order.payment_details = payment_details
          end

          def set_tip(amount)
            @order.tip = (amount * 100).to_i
          end

          def set_user_profile(user_profile)
            raise 'OrderBuilder::set_user_profile must be provided with an valid UserProfile instance' unless user_profile.instance_of?(Dashboard::Integration::SevenEleven::Models::UserProfile)

            @order.user_profile = user_profile
          end

          def set_commission_rate(rate)
            @order.commission_rate = rate.to_f
          end

          def set_commission_amount(amount)
            @order.commission_amt = (amount * 100).to_i
          end

          def set_payment_auth_code(auth_code)
            add_meta_data('auth_code', auth_code)
          end

          def set_tax_total(amount)
            add_meta_data('partner_tax', (amount * 100).to_i)
          end

          def set_fees(fees)
            @order.fees = (fees * 100).to_i
          end

          private

          def add_meta_data(key, value)
            @order.meta_info ||= {}
            @order.meta_info[key] = value
          end
        end
      end
    end
  end
end
