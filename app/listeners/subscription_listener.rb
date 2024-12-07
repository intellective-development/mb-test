class SubscriptionListener < Minibar::Listener::Base
  subscribe_to Subscription, RegisteredAccount

  def subscription_activated(subscription)
    SubscriptionNotifier.subscription_activated(subscription.id).deliver_later
  end

  def subscription_deactivated(subscription)
    SubscriptionNotifier.subscription_deactivated(subscription.id).deliver_later
  end

  def subscription_reminder(subscription)
    SubscriptionNotifier.subscription_reminder(subscription.id).deliver_later
  end

  def registered_account_canceled(account)
    SubscriptionCancelationWorker.perform_async(account.id)
  end

  def subscription_failure(subscription, message)
    Rails.logger.warn("SubscriptionWorkerError: #{message}; subscription_id: #{subscription.id}")

    SubscriptionNotifier.subscription_failure(subscription.id).deliver_later

    InternalAsanaNotificationWorker.perform_async(
      tags: [AsanaService::SUBSCRIPTION_ERROR_TAG_ID],
      name: "SUBSCRIPTION FAILURE: #{subscription.user.name}",
      notes: "Subscription ID: #{subscription.id}\n\nErrors: #{message}"
    )
  end
end
