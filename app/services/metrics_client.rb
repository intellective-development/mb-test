module MetricsClient
  class Metric
    class_attribute :api_client

    def self.client
      Metric.api_client ||= Dogapi::Client.new(ENV['DATADOG_API_KEY'])
    end

    def self.emit(metric, value)
      return if Rails.env.test?

      client.emit_point(metric, value, tags: ["env:#{ENV['ENV_NAME'] || 'local'}", 'service:minibar-web'])
    rescue RuntimeError
      # we should not fail if cant send the metric
    end
  end
end
