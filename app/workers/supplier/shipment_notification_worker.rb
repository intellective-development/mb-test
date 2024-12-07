class Supplier::ShipmentNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)

    supplier = shipment.supplier.get_supplier
    supplier.notification_methods.active.find_each do |notification_method|
      notification_method.send_notification(shipment)
    end
  end
end
