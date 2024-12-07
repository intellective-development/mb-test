class Supplier::FaxNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier'

  def perform_with_error_handling(notification_method_id, shipment_id, attempt = 1)
    notification_method = Supplier::NotificationMethod.find(notification_method_id)
    shipment            = Shipment.find(shipment_id)

    FaxNotification.notify(notification_method, shipment)
  rescue Minibar::FaxError => e
    raise e if attempt > 5

    Supplier::FaxNotificationWorker.perform_in(30.seconds, notification_method_id, shipment_id, attempt + 1)
  end
end
