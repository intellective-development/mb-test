class BlazerNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'notifications_internal'

  def perform_with_error_handling
    Blazer.send_failing_checks
  end
end
