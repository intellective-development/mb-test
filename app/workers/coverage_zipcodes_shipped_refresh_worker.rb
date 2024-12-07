# frozen_string_literal: true

# CoverageZipcodesShippedRefreshWorker
#
# Refresh coverage zipcodes shipped view
class CoverageZipcodesShippedRefreshWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: :backfill,
                  lock: :until_and_while_executing

  def perform_with_error_handling
    CoveredZipcodesShipped.refresh
  end
end
