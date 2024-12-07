class Supplier::OrderNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    order = Order.includes(:shipments).find(order_id)

    order.shipments.each do |shipment|
      supplier = shipment.supplier.get_supplier
      supplier.notification_methods.active.find_each do |notification_method|
        notification_method.send_notification(shipment)
      end
    end
  end
end
