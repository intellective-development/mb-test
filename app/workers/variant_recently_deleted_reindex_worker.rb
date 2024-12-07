class VariantRecentlyDeletedReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'backfill',
                  lock: :until_executing

  def perform_with_error_handling(supplier_id)
    MetricsClient::Metric.emit('reindex.worker.variant_recently_deleted_reindex_worker.run', 1)
    Variant.where('deleted_at > ? and supplier_id = ?', 30.minutes.ago, supplier_id).find_each(&:reindex_async)
  end
end
