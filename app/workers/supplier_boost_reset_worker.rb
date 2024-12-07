class SupplierBoostResetWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal'

  def perform_with_error_handling
    Supplier::Routing.reset_temporary_boost_factors
  end
end
