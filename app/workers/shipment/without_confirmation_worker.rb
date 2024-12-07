class Shipment::WithoutConfirmationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'default'

  # This worker should be used only for scheduled orders.
  def perform_with_error_handling(shipment_id, from_state = 'scheduled')
    shipment = Shipment.find shipment_id
    return unless shipment.scheduled_for
    # trying to avoid sending the asana notification twice. it can be triggered from:
    # transition to paid state, we will receive from_state attribute as paid and we only want to send that notification if the shipment is not on the scheduled state
    # transition to scheduled, we will send the notification is shipment is on scheduled state
    return unless (from_state == 'scheduled' && shipment.scheduled?) || (from_state == 'paid' && shipment.paid?)

    shipment.broadcast_event(:shipment_unconfirmed)
  end
end
