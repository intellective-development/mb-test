# https://api.iterable.com/api/docs#push_target
class PushNotificationService
  require 'faraday'
  API_KEY = ENV['ITERABLE_API_KEY']
  API_URL = "https://api.iterable.com/api/push/target?apiKey=#{API_KEY}".freeze

  class << self
    def send_notification(campaign, email, params)
      notification_params = {
        campaignId: campaign_id(campaign),
        recipientEmail: email,
        dataFields: params
      }
      client.post do |request|
        request.body = notification_params.to_json
      end
    end

    private

    def campaign_id(campaign)
      case campaign.to_s
      when 'custom_message'
        ENV['ITERABLE_PN_CUSTOM_MESSAGE_ID'].to_i
      when 'order_estimate'
        ENV['ITERABLE_PN_ORDER_ESTIMATE_ID'].to_i
      else
        raise IterableCampaignNotFound
      end
    end

    def client
      @client ||= Faraday.new(url: API_URL, ssl: { min_version: :TLS1_2 })
    end
  end
end

class IterableCampaignNotFound < StandardError; end
