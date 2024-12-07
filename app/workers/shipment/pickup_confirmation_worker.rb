class Shipment::PickupConfirmationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    CustomerNotifier.shipment_pickup_confirmation(shipment_id).deliver_now
  end
end
