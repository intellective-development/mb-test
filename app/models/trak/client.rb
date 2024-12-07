module Trak
  class Client
    require 'faraday'

    attr_reader :api_key

    def initialize(api_key)
      @api_key = api_key
    end

    def connection
      @connection ||= Faraday.new(url: 'https://onfleet.com/api/v2') do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.basic_auth @api_key, ''
      end
    end

    def request(method, path, data = nil)
      data = JSON.dump(data) unless data.nil?

      response = connection.run_request(method, path, data, nil) do |request|
        request.headers['Content-Type'] = 'application/json'
      end

      JSON.parse(response.body)
    end

    def get(path)
      request(:get, path)
    end

    def post(path, data)
      request(:post, path, data)
    end

    def put(path, data)
      request(:put, path, data)
    end

    def delete(path, data)
      request(:put, path, data)
    end
  end
end
