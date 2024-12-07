# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      # ShipStation SubscribeWebhooks Service
      class SubscribeWebhooks
        def initialize(credentials)
          @credentials = credentials
          @adapter = ShipStation::Integration.new(credentials)
        end

        def call
          @adapter.subscribe_to_webhooks(@credentials.supplier_id)
          true
        rescue Dashboard::Integration::ShipStation::Errors::UnauthorizedError,
               Dashboard::Integration::ShipStation::Errors::InvalidCredentialError
          false
        end
      end
    end
  end
end
