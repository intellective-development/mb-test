class ProductTypeSearchDataWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include Sidekiq::Throttled::Worker

  sidekiq_options retry: false,
                  queue: 'backfill',
                  lock: :until_and_while_executing

  sidekiq_throttle(concurrency: { limit: 2 },
                   threshold: { limit: 1_000, period: 1.hour })

  def perform_with_error_handling(product_type_id)
    product_type = ProductType.includes(:product_type_search_data).find(product_type_id)

    if product_type.product_type_search_data
      product_type.product_type_search_data.incremental_update!
    else
      product_type.create_product_type_search_data
      product_type.product_type_search_data.refresh!
    end
  end
end
