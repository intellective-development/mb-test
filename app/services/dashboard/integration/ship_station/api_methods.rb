# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      # ApiMethods is a module that implements the ApiMethodsInterface for ShipStation Integrations
      module ApiMethods
        def get_integration(supplier)
          ShipStation::Integration.new supplier.ship_station_credential
        end
      end
    end
  end
end
