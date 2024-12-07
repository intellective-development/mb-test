class SubscriptionWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 1,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling(subscription_id)
    subscription = Subscription.find(subscription_id)
    subscription.process! if subscription.active?
  end
end
