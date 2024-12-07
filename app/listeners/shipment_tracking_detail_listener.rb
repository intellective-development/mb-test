class ShipmentTrackingDetailListener < Minibar::Listener::Base
  subscribe_to Shipment::TrackingDetail

  def shipment_tracking_details_created(tracking_detail)
    ShipmentShippingConfirmationWorker.perform_at(6.hours.from_now, tracking_detail.shipment_id)
  end
end
