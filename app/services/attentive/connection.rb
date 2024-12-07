# frozen_string_literal: true

require 'faraday'

module Attentive
  module Connection
    extend ActiveSupport::Concern

    API_BASE_URL = ENV['ATTENTIVE_API_BASE_URL']
    API_TOKEN = ENV['ATTENTIVE_API_TOKEN']
    API_VERSION = 'v1'

    def connection
      Faraday.new API_BASE_URL do |conn|
        conn.path_prefix = API_VERSION
        conn.request :authorization, 'Bearer', API_TOKEN
        conn.request :json
        conn.response :json, content_type: 'application/json'
        conn.use :instrumentation
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
