class Shipment::SendPaymentCompletedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)
    Segments::SegmentService.from(shipment.order.storefront).payment_completed(shipment)
  end
end
