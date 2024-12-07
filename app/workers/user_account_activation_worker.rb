class UserAccountActivationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling(user_id)
    User::ActivateAccount.new(user_id).call
  end
end
