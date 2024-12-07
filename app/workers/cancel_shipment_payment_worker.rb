class CancelShipmentPaymentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      order.shipments.each do |shipment|
        shipment.trigger!(:cancel_payment) if shipment.in_state?(:paid)
      end
    end
  end
end
