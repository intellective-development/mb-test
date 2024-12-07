class UserOneSignalProfileUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'sync_profile',
                  lock: :until_and_while_executing

  def perform_with_error_handling(user_id)
    user = User.select(:id, :one_signal_id).find_by(id: user_id)
    OneSignalService.new(user.id).update_profile if user&.one_signal_id
  end
end
