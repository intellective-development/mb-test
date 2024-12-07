class InternalDailyStatusMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'notifications_internal',
                  lock: :until_and_while_executing,
                  run_lock_expiration: 60 * 60 # 1 hour

  def perform_with_error_handling
    AdminNotifier.daily_status.deliver_now if Feature[:daily_status_emails].enabled?
  end
end
