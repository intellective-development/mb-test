class ReferralCreditWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal'

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)

    if order.eligible_for_referral_credit?
      Referral.create(referral_user: order.user,
                      referring_user: User.find_by(referral_code: order.coupon.code),
                      purchased_at: order.confirmed_at)
    end
  end
end
