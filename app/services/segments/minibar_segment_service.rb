require 'segment/analytics'

module Segments
  class MinibarSegmentService < SegmentService
    def initialize
      @segment_client = Segment::Analytics.new(
        {
          write_key: ENV['SEGMENT_WRITE_KEY'],
          on_error: proc { |_status, msg| Rails.logger.error(msg) }
        }
      )
    end

    def identify(user)
      @segment_client.identify(user.as_segment_user)
    end

    def identify_gift_card_recipient(email)
      gift_card_recipient = GiftCard::Recipient.new(email)
      @segment_client.identify(gift_card_recipient.as_segment_recipient)
    end

    def identify_gift_order_recipient(order)
      details = order.gift_detail
      @segment_client.identify(details.as_segment_recipient)
    end

    def identify_email_capture(email, _user)
      email_capture = Waitlist::EmailCapture.new(email)
      @segment_client.identify(email_capture.as_segment_json)
    end

    def track_email_capture(email, _user)
      email_capture = Waitlist::EmailCapture.new(email)
      @segment_client.track(
        user_id: email_capture.segment_id,
        event: 'Email Captured',
        properties: email_capture.as_segment_object
      )
    end

    def gift_order_received(order)
      details = order.gift_detail
      return unless details.present?

      @segment_client.track(
        user_id: details.recipient_segment_id,
        event: 'giftOrderReceived',
        properties: details.as_segment_object
      )
    end

    def gift_order_cancelled(order)
      details = order.gift_detail
      return unless details.present?

      @segment_client.track(
        user_id: details.recipient_segment_id,
        event: 'giftOrderCancelled',
        properties: { order_number: order.number }
      )
    end

    def gift_card_received(gift_card, options = {})
      @segment_client.track(
        user_id: gift_card.recipient_segment_id,
        event: 'giftCardReceived',
        properties: gift_card.as_segment_gift_card(options)
      )
    end

    def gift_card_purchased(order_item)
      @segment_client.track(
        user_id: order_item.order.user.segment_id,
        event: 'giftCardPurchased',
        properties: order_item.as_segment_gift_card_purchase
      )
    end

    def gift_card_summary(email, gift_cards, file_url)
      summary = GiftCard::Summary.new(email, gift_cards, file_url)
      @segment_client.track(
        user_id: summary.segment_id,
        event: 'giftCardSummaryRequested',
        properties: summary.as_segment_event
      )
    end

    def gift_card_expired(gift_card)
      email = gift_card.recipient_email
      recipient = GiftCard::Recipient.new(email)
      @segment_client.track(
        user_id: recipient.segment_id,
        event: 'giftCardExpired',
        properties: {
          email: email,
          code: gift_card.code.upcase
        }
      )
    end

    def wrong_gift_card_received(email, code)
      gift_card_recipient = GiftCard::Recipient.new(email)
      @segment_client.track(
        user_id: gift_card_recipient.segment_id,
        event: 'wrongGiftCardReceived',
        properties: {
          email: email,
          code: code.upcase,
          deleteUser: !gift_card_recipient.exists_in_db?
        }
      )
    end

    def order_cancelled(order)
      @segment_client.track(
        user_id: order.user.segment_id,
        event: 'Order Cancelled',
        properties: order.as_segment_order
      )

      @segment_client.track(
        user_id: order.user.segment_id,
        event: 'Order Refunded',
        properties: order.as_segment_order
      )
    end

    def new_buyer_event(order)
      @segment_client.track(
        user_id: order.user.segment_id,
        event: 'New Buyer',
        properties: order.as_segment_order
      )
    end

    def guest_order_completed(order)
      @segment_client.track(
        user_id: order.user.segment_id,
        event: 'Guest Order Completed',
        properties: order.as_segment_order
      )
    end

    def zipcode_covered_event(user, promotion_type)
      @segment_client.track(
        user_id: user.segment_id,
        event: 'Zipcode Covered',
        properties: { promotion_type: promotion_type }
      )
    end

    def delivery_service_update(shipment, event, delivery_service_name = nil, _reference_id = nil)
      # TECH-4353 only send delivery notifications for orders with only one shipment
      # This is to avoid possible confusions of 2+ sms/push for the same client
      return if shipment.sibling_shipments.any?

      delivery_service_name ||= shipment.supplier.delivery_service&.name
      event_params = {
        order_id: shipment.order.number,
        supplier: shipment.supplier.name,
        delivery_service: delivery_service_name,
        update: event
      }
      @segment_client.track(
        user_id: shipment.order.user.segment_id,
        event: 'DeliveryServiceUpdate',
        properties: event_params
      )
    end

    def sms_identify(user, phone) end

    def sms_track(user, phone) end
  end
end
