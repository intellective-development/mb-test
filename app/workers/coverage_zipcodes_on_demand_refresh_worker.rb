# frozen_string_literal: true

# CoverageZipcodesOnDemandRefreshWorker
#
# Refresh coverage zipcodes on_demand view
class CoverageZipcodesOnDemandRefreshWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: :backfill,
                  lock: :until_and_while_executing

  def perform_with_error_handling
    CoveredZipcodesOnDemand.refresh
  end
end
