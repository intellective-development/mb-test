class Supplier::EmailNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier'

  def perform_with_error_handling(notification_method_id, shipment_id)
    SupplierNotifier.order_notification(notification_method_id, shipment_id)&.deliver_now
  end
end
