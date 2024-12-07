module Dashboard
  module Integration
    module ThreeJMS
      module ApiMethods
        REDIS_PREFIX = 'ThreeJMSDashboardService'.freeze

        def get_integration(supplier)
          Dashboard::Integration::ThreeJMS::Integration.new supplier
        end
      end
    end
  end
end
