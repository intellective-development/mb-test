module Dashboard
  module Integration
    module Specs
      module ApiMethods
        REDIS_PREFIX = 'SpecsDashboardService'.freeze

        def get_integration
          Dashboard::Integration::Specs::Integration.new get_access_token
        end

        def get_access_token
          token = ENV['SPECS_API_TOKEN']

          raise 'Spec\'s API token is not defined.' if token.blank?

          token
        end
      end
    end
  end
end
