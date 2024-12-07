class LateShipmentListener < Minibar::Listener::Base
  subscribe_to OrderAdjustment, Shipment

  def order_adjustment_created(order_adjustment)
    Shipment::LatenessWorker.perform_async(order_adjustment.shipment_id) if order_adjustment.reason.late?
  end

  # If a shipment is confirmed we want to check if it is late or not.
  def shipment_confirmed(shipment)
    ShipmentLateWorker.perform_async(shipment.id)
  end

  def shipment_late(shipment)
    CustomerNotifier.late_order(shipment.order_id).deliver_later
  end
end
