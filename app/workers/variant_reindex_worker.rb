class VariantReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: :searchkick_variant,
                  lock: :until_executed

  def perform_with_error_handling(id)
    MetricsClient::Metric.emit('reindex.worker.variant_reindex_worker.run', 1)
    Variant.find(id).reindex
  rescue ActiveRecord::RecordNotFound => e
    Variant.search(where: { id: id }, load: false).each do |document|
      Searchkick.client.delete(
        index: document._index,
        type: document._type,
        id: document._id,
        routing: document._routing
      )
    end
  end
end
