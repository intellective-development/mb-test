class SupplierOnfleetNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    DeliveryTracking.new(shipment_id)
  end
end
