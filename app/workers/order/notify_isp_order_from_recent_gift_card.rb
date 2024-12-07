class Order::NotifyISPOrderFromRecentGiftCard
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    return unless order.shipments.any?(&:pickup?)
    return unless order.all_gift_card_coupons.any? { |gc| gc.created_at >= 1.hour.ago }

    InternalNotificationService.notify_recent_gc_redeemed_for_isp(order)
  end
end
