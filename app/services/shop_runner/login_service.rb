module ShopRunner
  class LoginService
    require 'faraday'
    require 'faraday/detailed_logger'
    require 'typhoeus'
    require 'typhoeus/adapters/faraday'

    attr_reader :username, :password

    def initialize(username, password)
      @username = username
      @password = password
    end

    def call
      response = connection.post('app_login') do |req|
        req.body = { retailer: ENV['SHOPRUNNER_PARTNER_ID'], username: @username, password: @password }
      end
      JSON.parse(response.body, symbolize_names: true)
    end

    private

    def connection
      Faraday.new(url: ENV['SHOP_RUNNER_API_ENDPOINT']) do |faraday|
        faraday.basic_auth(ENV['SHOPRUNNER_API_USER'], ENV['SHOPRUNNER_API_PASSWORD'])
        faraday.adapter :typhoeus
        faraday.response :detailed_logger, Rails.logger, 'ShopRunner Login Request'
      end
    end
  end
end
