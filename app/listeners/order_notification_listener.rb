class OrderNotificationListener < Minibar::Listener::Base
  subscribe_to Order, Shipment

  def order_paid(order)
    # Supplier Facing
    standard_shipments = order.shipments.where(customer_placement: 'standard')
    standard_shipments.each do |shipment|
      Supplier::DashboardShipmentNotificationWorker.perform_async(shipment.id)
      Supplier::ShipmentNotificationWorker.perform_async(shipment.id)
    end

    # Customer Facing
    CustomerNotifier.order_confirmation(order.id).deliver_later
  end

  def order_confirmed(order)
    Notification::OrderDeliveryEstimate.new(order).perform if order.user.allows_delivery_estimate_push_notifications?
  end

  def shipment_gift_delivered(shipment)
    recently_scheduled = -> { (shipment.scheduled_for || shipment.created_at) > 2.days.ago }.call
    CustomerNotifier.shipment_gift_delivered(shipment.id).deliver_later if recently_scheduled && shipment.on_demand?
  end
end
