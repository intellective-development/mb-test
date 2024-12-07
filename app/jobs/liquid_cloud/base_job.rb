# frozen_string_literal: true

# Liquid Cloud Module
module LiquidCloud
  # Base Job Class
  class BaseJob < ActiveJob::Base # rubocop:disable Rails/ApplicationJob
    queue_as :notifications_internal

    LIQUID_CLOUD_BASE_URL = ENV['LIQUID_CLOUD_BASE_URL']

    def conn
      @conn ||= Faraday.new(url: LIQUID_CLOUD_BASE_URL) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter :net_http

        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Accept'] = 'application/json'
      end
    end
  end
end
