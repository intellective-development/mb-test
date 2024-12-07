class SupplierScoreUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(supplier_id)
    Supplier.find(supplier_id).update_score
  end
end
