class AppDownloadWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal'

  def perform_with_error_handling(phone)
    app_download_request = AppDownloadRequest.find_by(phone_number: phone)
    last_message_sent_dif = ((Time.current.utc - app_download_request.last_message_sent_at) / 1.minute).to_i if app_download_request.last_message_sent_at.present?

    if last_message_sent_dif.blank? || last_message_sent_dif >= 2
      PhoneNotification.sms_message(app_download_request.phone_number, I18n.t('text_messages.app_download_link', link: ENV['APP_DOWNLOAD_LINK']))

      app_download_request.last_message_sent_at = DateTime.now.utc
      app_download_request.save
    end
  end
end
