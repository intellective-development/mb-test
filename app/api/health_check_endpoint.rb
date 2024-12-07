require 'timeout'

class HealthCheckEndpoint < BaseAPI
  format :json
  prefix 'api'
  version 'v2', using: :path

  helpers do
    def sidekiq_service_status
      service_status = { sidekiq: 'healthy' }

      start_time = Time.now
      # begin
      #   Timeout.timeout(3) { Sidekiq.redis(&:info) }
      # rescue StandardError => e
      #   service_status[:sidekiq] = "error: #{e.message}"
      # end
      end_time = Time.now

      service_status[:sidekiq_check_time] = end_time - start_time
      service_status
    end

    def critical_service_status
      service_status = { database: 'healthy' }

      start_time = Time.now
      # begin
      #   Timeout.timeout(3) { ActiveRecord::Base.connection_pool.with_connection { |conn| conn.execute('SELECT 1') } }
      # rescue StandardError => e
      #   service_status[:database] = "error: #{e.message}"
      # end
      end_time = Time.now

      service_status[:database_check_time] = end_time - start_time
      service_status
    end
  end

  namespace :healthcheck do
    desc 'Endpoint used to know if app is running'
    get do
      status_code = 200
      service_status = {}

      # service_status.merge!(critical_service_status)
      # service_status.merge!(sidekiq_service_status)
      #
      # if service_status[:database] != 'healthy'
      #   Rails.logger.error("Healthcheck failed with status: #{service_status}")
      #   status_code = 500
      # end

      status status_code
      { status: status_code, description: service_status }
    end
  end

  namespace :canaries do
    desc 'Endpoint used to know if dependencies running'
    get do
      service_status = {}

      service_status.merge!(critical_service_status)
      service_status.merge!(sidekiq_service_status)

      { status: 200, description: service_status }
    end
  end

  namespace :queue_metrics do
    desc 'Endpoint used to share metrics about Sidekiq queues'
    get do
      begin
        Monitoring::SidekiqQueues.call
        status_code = 200
        description = 'OK'
      rescue StandardError => e
        status_code = 500
        description = e.message
      end

      status status_code
      { status: status_code, description: description }
    end
  end
end
