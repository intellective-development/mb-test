class Supplier::DashboardShipmentNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    Shipment.find(shipment_id).notify_supplier_dash
  end
end
