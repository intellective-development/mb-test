class Order::FireSegmentEventsService
  def self.call(order:)
    if order.storefront.default_storefront?
      Order::MinibarFireSegmentEventsService.call(order: order)
    else
      Order::StorefrontFireSegmentEventsService.call(order: order)
    end
  end
end
