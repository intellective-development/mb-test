module Dashboard
  module Integration
    module Bevmax
      module Error
        class StandardError < Dashboard::Integration::Errors::StandardError; end
        class OrderNotFoundError < Dashboard::Integration::Errors::StandardError; end
        class UnknownError < Dashboard::Integration::Errors::StandardError; end
        class UnauthorizedError < Dashboard::Integration::Errors::StandardError; end
        class BadRequestError < Dashboard::Integration::Errors::StandardError; end
      end
    end
  end
end
