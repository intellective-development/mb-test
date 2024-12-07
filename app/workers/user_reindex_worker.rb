class UserReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'reindex',
                  lock: :until_and_while_executing,
                  run_lock_expiration: 24 * 60 * 60 # 24 Hours

  def perform_with_error_handling
    User.reindex
  end
end
