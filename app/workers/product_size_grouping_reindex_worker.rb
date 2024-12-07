class ProductSizeGroupingReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: :searchkick_productsizegrouping,
                  lock: :until_executed

  def perform_with_error_handling(id)
    MetricsClient::Metric.emit('reindex.worker.product_size_grouping_reindex_worker.run', 1)
    ProductSizeGrouping.left_joins(%i[product_type hierarchy_category hierarchy_type hierarchy_subtype brand]).includes(%i[brand product_type hierarchy_category hierarchy_type hierarchy_subtype]).find(id).reindex
  rescue ActiveRecord::RecordNotFound => e
    ProductSizeGrouping.search(where: { id: id }, load: false).each do |document|
      Searchkick.client.delete(
        index: document._index,
        type: document._type,
        id: document._id,
        routing: document._routing
      )
    end
  end
end
