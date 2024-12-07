# frozen_string_literal: true

class SupplierNotificationServerService
  require 'faraday'

  attr_reader :notification_type, :channel_id

  def initialize(suppliers, type)
    @notification_type = type
    @channel_ids = suppliers.map { |s| s.get_supplier.channel_id }
  end

  def call
    send_to_notifications(notification_content)
  end

  private

  def send_to_notifications(body, endpoint = '/message')
    @channel_ids.each do |channel_id|
      if ENV['NOTIFICATION_SERVER_URL'].present?
        client.post do |request|
          request.url endpoint
          request.headers['Content-Type'] = 'application/json'
          request.body = body.merge({ channel_id: channel_id }).to_json
        end
      else
        Rails.logger.info("[Development] SupplierNotificationServerService: Channel #{channel_id}\nMessage: #{body}")
      end
    end
  end

  def client
    @client ||= Faraday.new(url: ENV['NOTIFICATION_SERVER_URL'], ssl: { verify: false })
  end

  def notification_content
    { notification_type: @notification_type }
  end
end
