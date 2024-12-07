# frozen_string_literal: true

module Dashboard
  # DashboardJobs handles API RateLimiting and retries
  module DashboardJobs
    include Sidekiq::Worker
    include WorkerErrorHandling

    def perform_with_error_handling(*args)
      perform_with_rate_limit(*args)
    rescue Dashboard::Integration::Errors::RateLimitError => e
      sleep (e.retry_in || 60).to_i
      retry
    end
  end
end
