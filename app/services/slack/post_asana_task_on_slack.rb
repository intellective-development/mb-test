# frozen_string_literal: true

module Slack
  # PostAsanaTaskOnSlack
  #
  # Handles posting Asana task contents into slack as a fallback
  class PostAsanaTaskOnSlack
    require 'slack'

    CHANNEL_NAME = '#feed'

    def initialize
      configure_slack
    end

    def call(asana_task_params)
      text = "Asana task posted: \n#{asana_task_params.to_yaml}"
      if ENV['SLACK_API_TOKEN'].blank?
        Rails.logger.info("[Development] Slack::PostAsanaTaskOnSlack: Channel #{CHANNEL_NAME}\n#{text}")
      else
        client.chat_postMessage(
          channel: CHANNEL_NAME,
          text: text,
          as_user: true
        )
      end
    end

    private

    def client
      @client ||= Slack::Web::Client.new
    end

    def configure_slack
      return unless ENV['SLACK_API_TOKEN'].present?

      Slack.configure do |config|
        (config.token = ENV['SLACK_API_TOKEN'])
      end
    end

    CUSTOMER_EMOJI = %w[👧 👨 👩 👴 👵 👨‍⚕️ 👩‍⚕ 💃 🕺 🧖‍ 👫 👬 👭].freeze

    def supplier_names
      @order.order_suppliers.pluck(:name).join(', ')
    end

    def region_name
      @order.shipments.first.region&.name || 'Unknown Region'
    end
  end
end
