class RegisteredAccountWaitlistUnsubscribeWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'default'

  def perform_with_error_handling(registered_account_id)
    registered_account = RegisteredAccount.includes(:user).find(registered_account_id)

    MailchimpService.new.unsubscribe_user_from_list(registered_account.user.id, ENV['MAILCHIMP_WAITLIST_LIST_ID'])
  end
end
