# frozen_string_literal: true

# handle sift api errors
module Fraud
  # mixin to call sift and retry on error
  module SiftRetryableCaller
    include SentryNotifiable

    def call_and_retry(&block)
      retry_counter = 2

      begin
        sift_response = block.call
        return sift_response if sift_response&.ok?

        raise Fraud::ResponseError.new(sift_response&.api_error_message, sift_response&.api_error_description, sift_response&.api_status)
      rescue StandardError => e
        retry if (retry_counter -= 1).positive?
        notify_sentry_and_log(e, "Exception when calling sift: #{e.message}")
        nil
      end
    end
  end
end
