class Supplier::SmsReminderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_supplier'

  def perform_with_error_handling(notification_method_id, shipment_id, reminder_type)
    notification_method = Supplier::NotificationMethod.find(notification_method_id)
    shipment            = Shipment.select(:id, :shipping_method_id, :order_id).includes(:order).find(shipment_id)

    if reminder_type == 'tracking'
      return unless shipment.shipped? && (shipment.tracking_detail.nil? || shipment.tracking_detail.reference.empty?)

      message = I18n.t('text_messages.order_tracking_reminder', number: shipment.order_number)
    else
      return unless shipment.paid?

      message = I18n.t('text_messages.order_reminder', number: shipment.order_number)
    end

    PhoneNotification.sms_message(notification_method.phone_number, message)
  end
end
