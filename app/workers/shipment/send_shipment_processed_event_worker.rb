class Shipment::SendShipmentProcessedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(package_id)
    package = Package.find(package_id)
    shipment = package.shipment

    Segments::SegmentService.from(shipment.order.storefront).shipment_processed(package)
  end
end
