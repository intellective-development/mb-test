class ShipmentReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: :searchkick_shipment,
                  lock: :until_executed

  def perform_with_error_handling(id)
    MetricsClient::Metric.emit('reindex.worker.shipment_reindex_worker.run', 1)
    Shipment.find(id).reindex
  rescue ActiveRecord::RecordNotFound => e
    Shipment.search(where: { id: id }, load: false).each do |document|
      Searchkick.client.delete(
        index: document._index,
        type: document._type,
        id: document._id,
        routing: document._routing
      )
    end
  end
end
