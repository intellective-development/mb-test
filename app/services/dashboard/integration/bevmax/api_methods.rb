module Dashboard
  module Integration
    module Bevmax
      module ApiMethods
        REDIS_PREFIX = 'BevmaxDashboardService'.freeze

        def get_integration
          Dashboard::Integration::Bevmax::Integration.new get_access_token
        end

        def get_access_token
          token = ENV['BEVMAX_API_TOKEN']

          raise 'Bevmax\'s API token is not defined.' if token.blank?

          token
        end
      end
    end
  end
end
