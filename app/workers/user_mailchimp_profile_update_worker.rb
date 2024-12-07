class UserMailchimpProfileUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  RETRY_WAIT_TIME = 5.minutes

  sidekiq_options retry: true,
                  queue: 'sync_profile',
                  lock: :until_executing

  def perform_with_error_handling(user_id)
    MailchimpService.new.subscribe_user_to_list(user_id, ENV['MAILCHIMP_USER_LIST_ID'])
  rescue Gibbon::MailChimpError => e
    Sentry.set_user(user_id: user_id)
    Sentry.capture_message("MailChimp: #{e.title}", extra: { detail: e.detail, body: e.body }) unless ['Member Exists', 'Member In Compliance State'].include?(e.title)

    UserMailchimpProfileUpdateWorker.perform_in(RETRY_WAIT_TIME, user_id) if e.status_code == 403 # Likely being rate limited, lets wait a moment and retry
  rescue Net::OpenTimeout => e
    UserMailchimpProfileUpdateWorker.perform_in(RETRY_WAIT_TIME, user_id)
  end
end
