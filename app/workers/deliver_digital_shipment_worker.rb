class DeliverDigitalShipmentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)

    return unless shipment.digital?
    return unless shipment.can_transition_to?(:delivered)

    shipment.deliver!
  end
end
