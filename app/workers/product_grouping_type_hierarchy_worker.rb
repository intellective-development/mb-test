class ProductGroupingTypeHierarchyWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'backfill',
                  lock: :until_and_while_executing

  def perform_with_error_handling(product_size_grouping_id)
    product_size_grouping = ProductSizeGrouping.includes(:product_type).find(product_size_grouping_id)

    hierarchy = product_size_grouping.product_type.sorted_self_and_ancestors

    product_size_grouping.hierarchy_category = hierarchy[0]
    product_size_grouping.hierarchy_type     = hierarchy[1]
    product_size_grouping.hierarchy_subtype  = hierarchy[2]
    product_size_grouping.save
  end
end
