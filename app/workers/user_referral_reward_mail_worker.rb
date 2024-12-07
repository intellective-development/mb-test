class UserReferralRewardMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(referral_id)
    CustomerNotifier.new_referral_credits(referral_id).deliver_now
  end
end
