class Coupon::GiftCardRefundWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find order_id
    order.all_gift_card_coupons.each do |gift_card|
      coupon_balance = gift_card.balance_for_order(order)
      next unless coupon_balance.positive?

      Coupon::CreateBalanceAdjustmentWorker.perform_async(gift_card.id, order_id: order.id, debit: false, amount: coupon_balance)
    end
  end
end
