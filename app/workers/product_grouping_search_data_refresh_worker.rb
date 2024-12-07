class ProductGroupingSearchDataRefreshWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: :backfill

  def perform_with_error_handling
    product_groupings = ProductSizeGrouping.joins(variants: [:order_items])
                                           .where(order_items: { created_at: Time.zone.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day })
                                           .select('product_groupings.id, product_groupings.product_type_id')
                                           .distinct

    product_types = product_groupings.pluck(:product_type_id)
                                     .uniq

    product_groupings.find_each do |product_grouping|
      ProductGroupingSearchDataWorker.perform_async(product_grouping.id)
    end

    product_types.each do |id|
      ProductTypeSearchDataWorker.perform_async(id)
    end
  end
end
