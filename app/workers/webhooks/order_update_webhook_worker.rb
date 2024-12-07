# frozen_string_literal: true

module Webhooks
  # order status webhooks
  class OrderUpdateWebhookWorker < Webhooks::WebhookWorker
    include SentryNotifiable

    LIQUID_CLOUD_BASE_URL = ENV['LIQUID_CLOUD_BASE_URL']
    LIQUID_CLOUD_WEBHOOK_ORDERS_PATH = '/v1/webhooks/orders'

    def send_webhook(order_id)
      order = Order.find(order_id)

      if order.nil?
        Rails.logger.error("OrderStatusUpdateWebhookWorker: Order #{order_id} not found")
        return
      end

      request_body = {
        targetUrl: order.storefront.webhook&.url,
        targetMethod: 'POST',
        storefrontPim: order.storefront.pim_name,
        order: InternalAPIV1::Entities::Order.represent(order).as_json
      }

      Rails.logger.debug("Sending webhook request to liquid cloud on url: #{LIQUID_CLOUD_BASE_URL} and path: #{LIQUID_CLOUD_WEBHOOK_ORDERS_PATH}")

      response = conn.post(LIQUID_CLOUD_WEBHOOK_ORDERS_PATH) do |req|
        req.body = request_body.to_json
      end

      Rails.logger.debug("Response from webhook: #{response}")
      response.body
    end

    def conn
      @conn ||= Faraday.new(url: LIQUID_CLOUD_BASE_URL) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.response :json

        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Accept'] = 'application/json'
      end
    end
  end
end
