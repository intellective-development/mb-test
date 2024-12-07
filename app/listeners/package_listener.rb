class PackageListener < Minibar::Listener::Base
  subscribe_to Package

  def package_delivered(package)
    shipment = package.shipment
    shipment.deliver! if shipment.all_packages_delivered? && shipment.can_transition_to?(:delivered)

    VideoGiftMessage::NotifyRecipientWorker.perform_async(shipment.order.video_gift_message.id) if shipment.order.video_gift_order?
  end

  def package_en_route(package)
    shipment = package.shipment
    shipment.start_delivery! if shipment.all_packages_en_route? && shipment.can_transition_to?(:en_route)
  end
end
