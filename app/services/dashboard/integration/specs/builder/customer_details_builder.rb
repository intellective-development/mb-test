module Dashboard
  module Integration
    module Specs
      module Builder
        class CustomerDetailsBuilder
          attr_reader :customer_details

          def self.build(existing_customer_details = nil)
            builder = new(existing_customer_details)
            yield(builder)
            builder.customer_details
          end

          def initialize(existing_customer_details = nil)
            if existing_customer_details.nil?
              @customer_details = Dashboard::Integration::Specs::Models::CustomerDetails.new
            else
              raise 'CustomerDetailsBuilder can be only initialized with nil or valid CustomerDetails instance' unless existing_customer_details.instance_of?(Dashboard::Integration::Specs::Models::CustomerDetails)

              @customer_details = existing_customer_details
            end
          end

          def set_first_name(first_name)
            @customer_details.first_name = first_name
          end

          def set_last_name(last_name)
            @customer_details.last_name = last_name
          end

          def set_email(email)
            @customer_details.email = email
          end

          def set_phone(phone)
            @customer_details.phone = phone
          end

          def set_city(city)
            @customer_details.city = city
          end

          def set_state(state)
            @customer_details.state = state
          end

          def set_zip_code(code)
            @customer_details.zip = code
          end

          def set_street(street)
            @customer_details.street_1 = street
            @customer_details.street_2 = ''
          end
        end
      end
    end
  end
end
