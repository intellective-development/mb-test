require 'sift'

module Fraud
  class OrderStatus
    include SentryNotifiable

    def initialize(order)
      @order = order
    end

    def check_order_status
      retry_count = 0
      begin
        response = client.get_order_decisions(@order.number)
        raise ResponseError.new(response&.api_error_message || 'Sift decision not received', response&.api_error_description, api_status: response&.api_status) unless response&.ok? && !response.body['decisions'].empty?

        decision_id = response.body.dig('decisions', 'payment_abuse', 'decision', 'id')
        Fraud::CreateSiftDecision.new({ type: 'order', id: @order.number },
                                      { id: decision_id }).call
      rescue ResponseError, StandardError => e
        case e
        when ResponseError
          if (e.status.nil? || e.status.negative?) && retry_count < 3
            # Truncated binary exponential backoff algorithm: retry API call
            retry_count += 1
            delay = [retry_count * 2, 15].min
            sleep rand(1..delay)
            retry
          end
        end

        notify_sentry_and_log(e, "Exception on Fraud::OrderStatus: #{e.message}")
        nil
      end
    end

    private

    def client
      @client ||= Sift::Client.new(
        api_key: ENV['SIFT_SCIENCE_API_KEY'],
        account_id: ENV['SIFT_ACCOUNT_ID'],
        version: ENV['SIFT_API_VERSION'] || 205
      )
    end
  end
end
