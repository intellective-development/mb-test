# frozen_string_literal: true

module Monitoring
  module Notifiers
    # Monitoring::Notifiers::GoogleMetric
    class GoogleMetric
      DATA = {
        'Sidekiq/MinibarWeb': {
          EnqueuedJobs: {
            description: 'Total number of enqueued jobs.'
          },
          QueueSize: {
            description: 'Number of enqueued jobs to specific queue.',
            labels: {
              QueueName: 'Name of queue'
            }
          }
        }
      }.freeze

      def initialize(options = {})
        @type = ['custom.googleapis.com', options[:namespace], options.fetch(:name)].compact.join('/')
        @data = DATA.dig(options[:namespace].to_sym, options.fetch(:name).to_sym).to_h
        delete! if options[:recreate]
        client.create_metric_descriptor(
          name: project_name,
          metric_descriptor: descriptor
        )
      end

      def delete!
        client.delete_metric_descriptor(name: metric_name)
      rescue StandardError
        nil
      end

      def add(metrics)
        return if metrics.blank?

        client.create_time_series(name: project_name, time_series: metrics.map { |metric| series(metric) })
      end

      protected

      def client
        @client ||= Google::Cloud::Monitoring.metric_service
      end

      def project_id
        ENV['GOOGLE_CLOUD_PROJECT_ID'] || Google::Cloud.configure.credentials.to_h['project_id']
      end

      def project_name
        @project_name ||= client.project_path(project: project_id)
      end

      def metric_name
        client.metric_descriptor_path(project: project_id, metric_descriptor: @type)
      end

      def descriptor
        Google::Api::MetricDescriptor.new(
          type: @type,
          metric_kind: Google::Api::MetricDescriptor::MetricKind::GAUGE,
          value_type: Google::Api::MetricDescriptor::ValueType::INT64,
          description: @data[:description],
          labels: @data[:labels].to_h.merge(env: 'Environment').map do |key, description|
            Google::Api::LabelDescriptor.new(description: description, key: key.to_s)
          end
        )
      end

      def resource
        resource = Google::Api::MonitoredResource.new(type: 'global')
        resource.labels['project_id'] = project_id
        resource
      end

      def point(value, time = Time.zone.now)
        end_time = Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec)
        point = Google::Cloud::Monitoring::V3::Point.new
        point.value = Google::Cloud::Monitoring::V3::TypedValue.new(int64_value: value)
        point.interval = Google::Cloud::Monitoring::V3::TimeInterval.new(end_time: end_time)
        point
      end

      def series(metric)
        labels = metric[:dimensions].to_a.to_h { |dimension| [dimension[:name], dimension[:value]] }
        series = Google::Cloud::Monitoring::V3::TimeSeries.new
        series.metric = Google::Api::Metric.new(type: @type, labels: labels)
        series.resource = resource
        series.points << point(metric[:value], metric[:timestamp])
        series
      end

      class << self
        def put_metric_data(namespace: nil, metric_data: [])
          metric_data.group_by { |metric| metric[:metric_name] }.each do |name, metrics|
            new(namespace: namespace, name: name).add(metrics)
          end
        end
      end
    end
  end
end
