class ShipmentShippingConfirmationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.includes(:tracking_detail).find(shipment_id)
    CustomerNotifier.shipment_shipping_confirmation(shipment.id).deliver_now if shipment.shipped?
  end
end
