class UserDeviseMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer'

  def perform_with_error_handling(notification, account_id, *args)
    account = RegisteredAccount.find(account_id)
    Devise.mailer.send(notification, account, *args).deliver_now
  end
end
