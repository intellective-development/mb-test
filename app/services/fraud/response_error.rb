# frozen_string_literal: true

module Fraud
  # Response Errors from SiftScience
  class ResponseError < StandardError
    attr_reader :status

    def initialize(message, description, status)
      message ||= 'Unexpected response from SiftScience'
      @status = status
      super "SiftScience Error #{status}: #{message} / #{description}."
    end
  end
end
