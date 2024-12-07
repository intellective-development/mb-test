module Dashboard
  module Integration
    module SevenEleven
      module Builder
        class UserProfileBuilder
          attr_reader :user_profile

          def self.build
            builder = new
            yield(builder)
            builder.user_profile
          end

          def initialize
            @user_profile = Dashboard::Integration::SevenEleven::Models::UserProfile.new
          end

          def set_first_name(first_name)
            @user_profile.first_name = first_name
          end

          def set_last_name(last_name)
            @user_profile.last_name = last_name
          end

          def set_phone_number(phone_number)
            @user_profile.phone_number = phone_number
          end
        end
      end
    end
  end
end
