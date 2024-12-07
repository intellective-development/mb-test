module WorkerErrorHandling
  def perform(*args)
    begin
      MetricsClient::Metric.emit("minibar.workers.#{self.class.name.downcase}.execution", 1)
    rescue StandardError
      # ignore metric emission errors
      Rails.logger.error('Unable to product metric for sidekiq job')
    end

    perform_with_error_handling(*args)
    MetricsClient::Metric.emit("minibar.workers.#{self.class.name.downcase}.success", 1)
  rescue StandardError => e
    args_map = if args.is_a?(Array) && args[0].is_a?(Hash) && args[1].nil?
                 args[0]
               else
                 method(:perform_with_error_handling).parameters.each_with_index.map do |(_, arg), idx|
                   [arg, args[idx]]
                 end.to_h
               end

    MetricsClient::Metric.emit("minibar.workers.#{self.class.name.downcase}.success", 0)
    Rails.logger.error("Error on #{self.class} with params #{args_map.to_json}: #{e}")
    Sentry.capture_message("#{e} on #{self.class}", { extra: args_map })

    raise e # Raise the error again to continue the standard flow
  end
end
