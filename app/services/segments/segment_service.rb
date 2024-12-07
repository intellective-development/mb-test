module Segments
  class SegmentService
    TIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%L%:z'.freeze
    DATE_FORMAT = '%F'.freeze
    DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%L%:z'.freeze

    def self.from(storefront)
      return MinibarSegmentService.new unless storefront
      return NoCommsService.new if storefront.omit_comms

      storefront.default_storefront? ? MinibarSegmentService.new : StorefrontCommsService.new(storefront)
    end

    def identify(user); end

    def identify_gift_card_recipient(email); end

    def identify_gift_order_recipient(order); end

    def identify_email_capture(email, user); end

    def track_email_capture(email, user); end

    def gift_order_received(order); end

    def gift_order_cancelled(order); end

    def gift_card_received(gift_card, options = {}); end

    def gift_card_purchased(order_item); end

    def gift_card_summary(email, gift_cards, file_url); end

    def gift_card_expired(gift_card); end

    def wrong_gift_card_received(email, code); end

    def order_cancelled(order); end

    def new_buyer_event(order); end

    def guest_order_completed(order); end

    def order_created(order); end

    def gift_order_created(order); end

    def order_finalized(order); end

    def order_fulfilled(order); end

    def order_refunded(order); end

    def order_updated(order, update_type); end

    def zipcode_covered_event(user, promotion_type); end

    def delivery_service_update(shipment, event, delivery_service_name = nil, reference_id = nil); end

    def sms_identify(user, phone); end

    def sms_track(user, phone); end

    def order_tracking_updated(package, subtag, subtag_message, gift_individual = :other); end

    def gift_order_tracking_updated(package, subtag, subtag_message); end

    def video_gift_order_recording_requested(video_gift_message); end

    def video_gift_order_message_recorded(video_gift_message); end

    def payment_completed(shipment); end

    def shipment_processed(package); end

    def aging_backorder_notification_created(shipment); end

    def aging_order_notification_created(shipment); end

    def products_ordered(order); end

    def products_refunded(order, order_item = nil); end

    def membership_created(membership); end

    def membership_cancelled(membership); end

    def membership_renewal(membership); end

    def membership_payment_completed(membership); end

    def membership_payment_failed(membership); end

    def membership_refunded(membership); end
  end
end
