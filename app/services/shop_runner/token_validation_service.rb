module ShopRunner
  class TokenValidationService
    require 'faraday'
    require 'faraday/detailed_logger'
    require 'typhoeus'
    require 'typhoeus/adapters/faraday'

    attr_reader :token

    def initialize(token)
      @token = token
    end

    def call
      response = connection.get do |req|
        req.params['format'] = 'json'
        req.params['srtoken'] = token
      end

      response_json = JSON.parse(response.body, symbolize_names: true)
      response_json[:validationResult]
    rescue StandardError
      false
    end

    private

    def connection
      Faraday.new(url: ENV['SHOPRUNNER_API_VALIDATION_URL']) do |faraday|
        faraday.basic_auth(ENV['SHOPRUNNER_API_USER'], ENV['SHOPRUNNER_API_PASSWORD'])
        faraday.adapter  :typhoeus
        faraday.response :detailed_logger, Rails.logger, 'ShopRunner Request'
      end
    end
  end
end
