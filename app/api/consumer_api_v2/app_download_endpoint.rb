class ConsumerAPIV2::AppDownloadEndpoint < BaseAPIV2
  format :json

  resource :app_download_link do
    desc 'Trigger app download link to be sent to phone number'
    params do
      requires :phone, type: String, desc: 'Phone number to send link to'
    end
    post do
      app_download_request = AppDownloadRequest.find_or_initialize_by(phone_number: PhonyRails.normalize_number(params[:phone]))
      error!('Phone number is not valid.') if app_download_request.invalid?
      app_download_request.save
      AppDownloadWorker.perform_async(app_download_request.phone_number)
    end
  end
end
