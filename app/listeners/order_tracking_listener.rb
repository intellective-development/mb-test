class OrderTrackingListener < Minibar::Listener::Base
  subscribe_to Order

  def order_paid(order)
    ButtonTrackingWorker.perform_async(order.id)
    ShopRunner::OrderPixelWorker.perform_async(order.id)
    ShopRunner::OrderTrackingWorker.perform_async(order.id)
  end

  def order_confirmed(order)
    ShopRunner::ShipmentWorker.perform_async(order.id)
  end

  def order_canceled(order)
    ButtonCancelationWorker.perform_async(order.id)
    ShopRunner::OrderCancelationWorker.perform_async(order.id)
  end
end
