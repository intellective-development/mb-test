class ProductGroupingWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'backfill'

  def perform_with_error_handling(product)
    ProductSizeGrouping.group_product(product)
  end
end
