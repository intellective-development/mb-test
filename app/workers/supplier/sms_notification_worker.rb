class Supplier::SmsNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier'

  def perform_with_error_handling(notification_method_id, shipment_id)
    notification_method = Supplier::NotificationMethod.find(notification_method_id)
    shipment            = Shipment.select(:id, :order_id).includes(:order).find(shipment_id)

    PhoneNotification.sms_message(notification_method.phone_number, I18n.t('text_messages.order_notification', number: shipment.order_number))
  end
end
