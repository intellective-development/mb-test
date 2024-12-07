class ProductGroupingAndVariantReindexByBrandWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: :backfill,
                  lock: :until_executed

  def perform_with_error_handling(brand_id)
    brand = Brand.find brand_id
    brand.product_size_groupings.find_each do |product_grouping|
      product_grouping.reindex_async
      product_grouping.variants.find_each(&:reindex_async)
    end
  end
end
