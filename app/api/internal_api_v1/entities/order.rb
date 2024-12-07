# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # Order entity for internal API v1
    class Order < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt&.iso8601 }

      expose :user do |object|
        {
          email: object.user&.email,
          name: object.user&.name,
          email_subscribed: object.user&.email_subscribed,
          sms_subscribed: object.user&.sms_subscribed
        }
      end
      expose :number
      expose :state
      expose :email
      expose :birthdate
      expose :storefront_id
      expose :storefront_pim_name do |object|
        object.storefront.pim_name
      end
      expose :created_at, format_with: :iso_timestamp
      expose :updated_at, format_with: :iso_timestamp

      expose :amounts do |object, _options|
        InternalAPIV1::Entities::Amounts.represent(object)
      end

      expose :payment_profile, with: InternalAPIV1::Entities::PaymentProfile

      expose :gift_options, if: ->(instance, _options) { instance.gift? } do
        expose :gift_message,         as: :message
        expose :gift_recipient,       as: :recipient_name
        expose :gift_recipient_phone, as: :recipient_phone
        expose :gift_recipient_email, as: :recipient_email
      end

      expose :delivery_notes
      expose :ship_address, as: :shipping_address, if: ->(instance, _options) { instance.shipments.any?(&:on_demand?) || instance.shipments.any?(&:shipped?) }, with: InternalAPIV1::Entities::Address

      expose :shipments, with: InternalAPIV1::Entities::OrderShipment
      expose :comments, with: InternalAPIV1::Entities::Comment

      private

      def gift_recipient
        object.gift_detail.recipient_name
      end

      def gift_recipient_phone
        object.gift_detail.recipient_phone
      end

      def gift_recipient_email
        object.gift_detail.recipient_email
      end

      def gift_message
        object.gift_detail.message
      end
    end
  end
end
