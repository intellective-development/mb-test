module CouponFirstPurchase
  def eligible?(order, at = nil)
    at ||= order.completed_at || Time.zone.now
    (starts_at <= at && expires_at >= at) && eligible_for_first_purchase?(order, at)
  end

  def eligible_for_first_purchase?(order, at = nil)
    at ||= order.completed_at || Time.zone.now
    finished_orders = order.user.try(:number_of_finished_orders_at, at)
    finished_orders.nil? || finished_orders.zero?
  end
end
