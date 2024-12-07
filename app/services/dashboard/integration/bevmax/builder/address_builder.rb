module Dashboard
  module Integration
    module Bevmax
      module Builder
        class AddressBuilder
          attr_reader :address

          def self.build(existing_address = nil)
            builder = new(existing_address)
            yield(builder)
            builder.address
          end

          def initialize(existing_address = nil)
            if existing_address.nil?
              @address = Dashboard::Integration::Bevmax::Models::Address.new
              @address.country = 'USA'
            else
              raise 'AddressBuilder can be only initialized with nil or valid Address instance' unless existing_address.instance_of?(Dashboard::Integration::Bevmax::Models::Address)

              @address = existing_address
            end
          end

          def set_name(name)
            @address.name = name
          end

          def set_email(email)
            @address.email = email
          end

          def set_phone(phone)
            @address.phone = phone
          end

          def set_city(city)
            @address.city = city
          end

          def set_state(state)
            @address.state = state
          end

          def set_zip_code(code)
            @address.zip_code = code
          end

          def set_address1(address)
            @address.address1 = address
          end

          def set_address2(address)
            @address.address2 = address
          end

          def set_country(country)
            @address.country = country
          end
        end
      end
    end
  end
end
