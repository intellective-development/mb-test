class UserProfileDeltaUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'backfill',
                  lock: :until_and_while_executing

  def perform_with_error_handling(user_id, order_id)
    UserProfileDeltaUpdateService.new(user_id, order_id).call
  end
end
