# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Errors
        class StandardError < Dashboard::Integration::Errors::StandardError; end

        # This error is raised when the ShipStation API returns an error that we don't know how to handle, like 500
        class UnknownError < Dashboard::Integration::Errors::StandardError
          def initialize(shipment_id, action = 'order submission', msg = '')
            super("Unknown ShipStation response. Could not successfully complete ShipStation shipment #{shipment_id} #{action}.#{msg.present? ? " #{msg}" : ''}")
          end
        end

        # This error is raised when the ShipStation API returns a 401 response, indicating that the API credentials are invalid
        class UnauthorizedError < Dashboard::Integration::Errors::StandardError
          def initialize(shipment_id, action = 'order submission', msg = '')
            super("Could not successfully complete ShipStation shipment #{shipment_id} #{action}.#{msg.present? ? " #{msg}" : ''}")
          end
        end

        # This error is raised when the ShipStation API returns a 400 response, indicating that the order submission was invalid
        class BadRequestError < Dashboard::Integration::Errors::StandardError
          def initialize(shipment_id, action = 'order submission', msg = '')
            super("Could not successfully complete ShipStation shipment #{shipment_id} #{action}.#{msg.present? ? " #{msg}" : ''}")
          end
        end

        # This error is raised when the Supplier has not a ShipStation credentials set up
        class InvalidCredentialError < Dashboard::Integration::Errors::StandardError
          def initialize(msg = '')
            super("ShipStation credentials are missing.#{msg.present? ? ": #{msg}" : ''}")
          end
        end

        # This error is raised when the ShipStation API returns a 429 response, indicating that the API rate limit has been reached
        class RateLimitError < Dashboard::Integration::Errors::RateLimitError; end
      end
    end
  end
end
