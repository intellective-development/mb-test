class CoverageZipcodesRefreshWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: :backfill,
                  lock: :until_executed

  def perform_with_error_handling
    CoveredZipcodesOnDemand.refresh
    CoveredZipcodesShipped.refresh
  end
end
