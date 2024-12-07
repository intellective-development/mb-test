module Dashboard
  module Integration
    module SevenEleven
      module Builder
        class ShippingBuilder
          attr_reader :shipping

          def self.build(existing_shipping = nil)
            builder = new(existing_shipping)
            yield(builder)
            builder.shipping
          end

          def initialize(existing_shipping = nil)
            if existing_shipping.nil?
              @shipping = Dashboard::Integration::SevenEleven::Models::Shipping.new
            else
              raise 'ShippingBuilder can be only initialized with nil or valid Shipping instance' unless existing_shipping.instance_of?(Dashboard::Integration::SevenEleven::Models::Shipping)

              @shipping = existing_shipping
            end
          end

          def set_city(city)
            @shipping.city = city
          end

          def set_state(state)
            @shipping.state = state
          end

          def set_zip_code(code)
            @shipping.zip = code
          end

          def set_street(street)
            @shipping.street = street
          end

          def set_geo_position(lat, lng)
            @shipping.lat = lat
            @shipping.lng = lng
          end

          def set_delivery_note(note)
            @shipping.delivery_notes = note[0...255]
          end
        end
      end
    end
  end
end
