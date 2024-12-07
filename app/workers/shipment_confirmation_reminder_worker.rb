# frozen_string_literal: true

# ShipmentConfirmationReminderWorker
#
# Worker to send notification to supplier on shipment confirmation
class ShipmentConfirmationReminderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 10,
                  queue: 'internal',
                  lock: :until_executing

  # rubocop:disable Style/OptionalBooleanParameter
  def perform_with_error_handling(shipment_id, resended = false)
    shipment = Shipment.find(shipment_id)

    return if resended && shipment.confirmed?

    shipment.send_confirmation_reminder
    resend_confirmation_remider(shipment) unless resended
  end
  # rubocop:enable Style/OptionalBooleanParameter

  def resend_confirmation_remider(shipment)
    ShipmentConfirmationReminderWorker.perform_at(14.minutes.from_now, shipment.id, true)
  end
end
