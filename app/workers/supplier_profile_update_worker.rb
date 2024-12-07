class SupplierProfileUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'backfill',
                  lock: :until_and_while_executing

  def perform_with_error_handling(supplier_id)
    supplier = Supplier.includes(:profile).find(supplier_id)
    # Removing this due to performance issues and because it seems like it is not used.
    supplier.profile&.set_category_metadata
    supplier.profile&.set_type_metadata
  end
end
