class ShipmentUnconfirmedCommentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 10,
                  queue: 'internal',
                  lock: :until_executing

  def perform_with_error_handling(shipment_id, from_state = 'paid')
    shipment = Shipment.find(shipment_id)
    # avoid triggering it twice for scheduled orders
    return if shipment.scheduled? && from_state == 'paid'

    shipment.add_unconfirmed_comment
  end
end
