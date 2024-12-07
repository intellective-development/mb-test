# TODO: We are only using API::Errors::CardError and API::Errors::BrainTree here.

module API
  module Errors
    # This base class should not be used directly.
    class ErrorBase < StandardError
      attr_reader :code, :name, :description, :http_status

      def initialize(description = 'An unknown exception has occurred', extra = {})
        @code        = 400
        @http_status = 404
        @name        = self.class.to_s.sub(/^API::Errors::/, '')
        @description = description
        @extra = extra
      end

      def to_s
        "#{code} - #{name}: #{description}"
      end

      def as_json(options = {})
        options = @extra.merge(options)
        options.merge(code: code,
                      name: name,
                      description: description)
      end
    end

    # This base class should not be used directly.
    class Base < ErrorBase
      attr_reader :http_status

      def initialize(description = 'An unknown exception has occurred')
        super

        @name = self.class.to_s.sub(/^API::Errors::/, '')
        @http_status = 500
      end
    end

    class BadRequest < Base
      def initialize(description = 'Your request is invalid')
        super
        @code = @http_status = 400
      end
    end

    class ApplePayError < BadRequest
      def initialize(*_args)
        super('We were unable to verify your apple pay information. Please try again, or try another payment method.')
      end
    end

    class PaypalError < BadRequest
      def initialize(*_args)
        super('We were unable to verify your paypal information. Please try again, or try another payment method.')
      end
    end

    class CardError < BadRequest
      def initialize(*_args)
        super('We were unable to verify your credit card information. Please verify your card details and billing address, or try another card.')
      end
    end

    class CardVerificationError < CardError; end

    class CreatePaymentMethodError < CardError
      def initialize(*_args)
        super('We were unable to verify your payment information. Please verify your payment information and try again.')
      end
    end

    class BrainTreeError < BadRequest
      def initialize(*_args)
        super('We were unable to verify your credit card information. Please verify your card details and billing address, or try another card.')
      end
    end
  end
end
