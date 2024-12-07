class SupplierEmailNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier',
                  lock: :until_and_while_executing

  def perform_with_error_handling(_notification_method_id, shipment_id, employee_id)
    SupplierNotifier.order_notification(nil, shipment_id, employee_id)&.deliver_now
  end
end
