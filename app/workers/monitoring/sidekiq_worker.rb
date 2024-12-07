# frozen_string_literal: true

module Monitoring
  # Monitoring::SidekiqWorker
  class SidekiqWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options queue: 'monitoring', retry: false

    def perform_with_error_handling
      # Rails.logger.info("[Monitoring] SidekiqQueues.call: #{Time.zone.now}")
      # Monitoring::SidekiqQueues.call
      # Rails.logger.info('[Monitoring] SidekiqQueues.call end')

      url = ENV['ENV_NAME'] == 'master' ? 'https://minibar-web-production-409827160732.us-central1.run.app' : 'https://staging.minibardelivery.com'
      conn = Faraday.new(url: url) do |faraday|
        faraday.response :json
        faraday.adapter :net_http

        faraday.headers['Content-Type'] = 'application/json'
      end

      conn.get 'api/v2/queue_metrics'
    end
  end
end
