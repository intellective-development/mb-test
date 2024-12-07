# frozen_string_literal: true

module Monitoring
  # Monitoring::SidekiqQueues
  class SidekiqQueues < BaseService
    attr_reader :params

    def call
      send_to_cloud!
    end

    private

    def send_to_cloud!
      send_google_cloud_metrics('Sidekiq/MinibarWeb', metrics_arr)
    end

    def send_google_cloud_metrics(namespace, metrics, dimensions = {})
      return if Google::Cloud.configure.credentials.blank? && !Google::Auth::GCECredentials.on_gce?

      Monitoring::Notifiers::GoogleMetric
        .put_metric_data(namespace: namespace, metric_data: add_dimensions(metrics, dimensions))
    end

    def add_dimensions(metrics, dimensions = {})
      additional_dimensions =
        { env: env_name }.merge(dimensions).map { |k, v| { name: k.to_s, value: v.to_s } }
      metrics.map do |metric|
        metric.merge(dimensions: metric[:dimensions].to_a + additional_dimensions)
      end
    end

    def env_name
      ENV['ENV_NAME'] == 'master' ? 'production' : ENV['ENV_NAME']
    end

    def metrics_arr
      sidekiq_stats = HireFire::Resource.dynos.map { |config| { name: config[:name], value: config[:quantity].call } }

      [build_enqueued_jobs(sidekiq_stats)] + build_queue_sizes(sidekiq_stats)
    end

    def build_queue_sizes(sidekiq_stats)
      sidekiq_stats.map do |sidekiq_stat|
        build_queue_size(sidekiq_stat)
      end
    end

    def build_queue_size(sidekiq_stat)
      {
        metric_name: 'QueueSize',
        dimensions: [{ name: 'QueueName', value: sidekiq_stat[:name] }],
        timestamp: now,
        value: sidekiq_stat[:value],
        unit: 'Count'
      }
    end

    def build_enqueued_jobs(sidekiq_stats)
      {
        metric_name: 'EnqueuedJobs',
        timestamp: now,
        value: sidekiq_stats.sum { |sidekiq_stat| sidekiq_stat[:value] },
        unit: 'Count'
      }
    end

    def now
      @now ||= Time.zone.now
    end
  end
end
