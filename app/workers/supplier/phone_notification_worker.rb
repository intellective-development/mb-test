class Supplier::PhoneNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier'

  def perform_with_error_handling(notification_method_id, _shipment_id)
    notification_method = Supplier::NotificationMethod.find(notification_method_id)
    PhoneNotification.voice_call(notification_method.phone_number, I18n.t('text_messages.order_notification_call'))
  end
end
