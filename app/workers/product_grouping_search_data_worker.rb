class ProductGroupingSearchDataWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include Sidekiq::Throttled::Worker

  sidekiq_options retry: false,
                  queue: 'backfill',
                  lock: :until_and_while_executing

  # Since we are refreshing (vs. incremental update), this gets expensive from
  # a database perspective hence the throttling.
  sidekiq_throttle(concurrency: { limit: 1 },
                   threshold: { limit: 1_000, period: 1.hour })

  def perform_with_error_handling(product_size_grouping_id)
    product_size_grouping = ProductSizeGrouping.includes(:product_grouping_search_data).find(product_size_grouping_id)

    if product_size_grouping.product_grouping_search_data
      product_size_grouping.product_grouping_search_data.incremental_update!
    else
      product_size_grouping.create_product_grouping_search_data
      product_size_grouping.product_grouping_search_data.refresh!
    end
  end
end
