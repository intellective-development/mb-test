class UserProfileUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'backfill',
                  lock: :until_and_while_executing

  def perform_with_error_handling(user_id)
    user = User.includes(:profile).find(user_id)
    user.profile.update(user.profile_data)
  end
end
