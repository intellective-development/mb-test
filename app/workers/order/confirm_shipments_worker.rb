class Order::ConfirmShipmentsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      order.shipments.in_state(:paid, :confirmed, :scheduled).each do |shipment|
        next if shipment.digital? # digital shipments are confirmed when order is placed

        if shipment.scheduled_for.nil? || shipment.scheduled? || !shipment.can_transition_to?(:scheduled)
          shipment.confirm!
        else
          shipment.schedule!
        end
      end
    end
  end
end
