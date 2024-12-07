# HISTORY
# This API is used as part of a gifting promotion being ran with Beam Suntory and PrizeLogic (a 3rd party vendor) where the gift
# sender is prompted to record a video message for the recipient.
#
# It is used to trigger an email send by Minibar to the recipient of a gift order which includes the `message_url` provided.

class PrizeLogicAPIV1 < BaseAPIV1
  format :json
  prefix 'callbacks'

  helpers do
    def authenticate!
      error!('Unauthorized', 401) if headers['Authorization'] != "Token #{ENV['PRIZE_LOGIC_AUTH_TOKEN']}"
    end
  end

  namespace :gift_message do
    desc 'Endpoint for callbacks from Beam/PrizeLogic\s seasonal gifting campaign'
    params do
      requires :code,        type: String, desc: 'Unique code, used to validate and associate the request with an order.'
      requires :message_url, type: String, regexp: CustomValidators::Urls.url_validator, desc: 'A URL to a pre-recorded gift message.'
      optional :recipient,   type: String, regexp: CustomValidators::Emails.email_validator, desc: 'An email address correspondong to the gift recipient.'
    end
    before do
      authenticate!
    end
    post do
      puts "PRIZELOGIC: Code - #{params[:code]} - #{params.slice(:message_url, :recipient)}"

      one_time_code = OneTimeCode.prize_logic.where('lower(code) = lower(?)', params[:code]).first

      error!('Code is invalid', 404)            unless one_time_code
      error!('Code has not been assigned', 400) unless one_time_code.used
      error!('Code has been used', 400)         if one_time_code.metadata

      one_time_code.update(metadata: params.slice(:message_url, :recipient))
      PrizeLogicNotificationWorker.perform_at(one_time_code.order.scheduled_for || Time.current + 5.minutes, one_time_code.id)

      status 200
    end
  end
end
