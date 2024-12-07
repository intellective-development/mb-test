class PushNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 10,
                  queue: 'push_notifications',
                  lock: :until_and_while_executing

  def perform_with_error_handling(campaign, email, params)
    PushNotificationService.send_notification(campaign, email, params)
  end
end
