# frozen_string_literal: true

module Dashboard
  module Integration
    module Errors
      # Dashboard::Integration::Errors::StandardError
      class StandardError < ::StandardError
        def initialize(message)
          super
          set_backtrace(caller)
        end
      end

      # Dashboard::Integration::Errors::RateLimitError
      class RateLimitError < StandardError
        attr_reader :retry_in

        def initialize(retry_in: 30)
          @retry_in = retry_in
          super("#{self.class.name}: Retrying in #{retry_in} seconds.")
        end
      end

      # Dashboard::Integration::Errors::PublicError
      class PublicError < StandardError
        attr_reader :name, :extra

        def initialize(message, name = nil, extra = nil)
          super(message)
          @name = name
          @extra = extra
        end

        def error_payload
          payload = { message: message, name: 'GenericIntegrationError' }
          payload[:name] = @name unless @name.nil?
          payload[:extra] = @extra unless @extra.nil?

          payload
        end
      end
    end
  end
end
