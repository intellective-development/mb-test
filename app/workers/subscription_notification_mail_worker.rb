class SubscriptionNotificationMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(subscription_id)
    subscription = Subscription.find(subscription_id)
    subscription.publish_subscription_reminder if subscription.active?
  end
end
