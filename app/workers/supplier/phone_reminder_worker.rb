class Supplier::PhoneReminderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier'

  def perform_with_error_handling(notification_method_id, shipment_id, reminder_type)
    notification_method = Supplier::NotificationMethod.find(notification_method_id)
    shipment            = Shipment.find(shipment_id)

    if reminder_type == 'tracking'
      return unless shipment.shipping_method&.shipped? && (shipment.tracking_detail.nil? || shipment.tracking_detail.reference.empty?)

      message = I18n.t('text_messages.order_tracking_reminder_call')
    else
      return unless shipment.paid?

      message = I18n.t('text_messages.order_reminder_call')
    end

    PhoneNotification.voice_call(notification_method.phone_number, message)
  end
end
