class Coupon::CreateBalanceAdjustmentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(coupon_id, options = {})
    debit, amount, order_id = options.to_options.fetch_values(:debit, :amount, :order_id)

    CouponDecreasingBalance.find(coupon_id).tap do |coupon|
      coupon.coupon_balance_adjustments.create!(amount: amount, debit: debit, order_id: order_id)
    end
  end
end
