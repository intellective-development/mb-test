class SubscriptionCancelationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(account_id)
    user_scope = User.where(account_type: 'RegisteredAccount', account_id: account_id)
    Subscription.joins(:user).merge(user_scope).find_each(&:cancel!)
  end
end
