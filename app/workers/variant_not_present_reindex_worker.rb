class VariantNotPresentReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 2,
                  queue: 'reindex_variant_not_present',
                  lock: :until_executing

  def perform_with_error_handling(supplier_id)
    MetricsClient::Metric.emit('reindex.worker.variant_not_present_reindex_worker.run', 1)

    Variant
      .self_active
      .joins(:inventory)
      .where(Variant.arel_table[:updated_at].gt(15.minutes.ago))
      .where(supplier_id: supplier_id)
      .where(inventories: { count_on_hand: 0 })
      .includes(product: [:product_size_grouping])
      .find_each(batch_size: 1000) do |variant|
        variant&.reindex_async
        variant&.product&.reindex_async
        variant&.product&.product_size_grouping&.reindex_async
      end
  end
end
