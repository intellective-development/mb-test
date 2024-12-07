# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Builders
        # AddressBuilder is a class that implements the AddressBuilderInterface for ShipStation Integrations
        class AddressBuilder
          include Dashboard::Integration::ShipStation::Models

          attr_reader :address

          def self.build(existing_address = nil)
            builder = new(existing_address)
            yield(builder)
            builder.address
          end

          def initialize(existing_address = nil)
            if existing_address.nil?
              @address = Address.new
              @address.country = 'USA'
            else
              raise 'AddressBuilder can be only initialized with nil or valid Address instance' unless existing_address.instance_of?(Address)

              @address = existing_address
            end
          end

          def with_name(name)
            @address.name = name
          end

          def with_company(company)
            @address.company = company
          end

          def with_city(city)
            @address.city = city
          end

          def with_state(state)
            raise 'with_state must receive a valid State instance' unless state.is_a?(::State)

            @address.state = state
          end

          def with_zip_code(code)
            @address.zip_code = code
          end

          def with_address1(address)
            @address.address1 = address
          end

          def with_address2(address)
            @address.address2 = address
          end

          def with_phone(phone)
            @address.phone = phone
          end

          def with_country(country)
            @address.country = country
          end
        end
      end
    end
  end
end
