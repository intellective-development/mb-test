class KnownProductReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: :searchkick_known_product,
                  lock: :until_executed

  def perform_with_error_handling(id)
    BuildKnownProductsIndexService.new.update_product(id)
  end
end
