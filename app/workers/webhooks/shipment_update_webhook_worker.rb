# frozen_string_literal: true

module Webhooks
  # shipment status webhooks
  class ShipmentUpdateWebhookWorker < Webhooks::WebhookWorker
    SHIPMENT_UPDATE_WEBHOOK_TOPIC = ENV['GCLOUD_PUBSUB_SHIPMENT_UPDATE_TOPIC']

    def send_webhook(shipment_id)
      shipment = Shipment.find_by(id: shipment_id)

      if shipment.nil?
        Rails.logger.error("ShipmentStatusUpdateWebhookWorker: Shipment #{shipment_id} not found")
        return
      end

      shipment_payload = Webhooks::Entities::Shipment.represent(shipment)

      payload = {
        eventType: 'shipment_update',
        shipment: shipment_payload
      }.to_json

      PubsubPublisherService.publish_message(SHIPMENT_UPDATE_WEBHOOK_TOPIC, payload)
      Rails.logger.debug("Message published to PubSub with the following content: #{payload}")
    end
  end
end
