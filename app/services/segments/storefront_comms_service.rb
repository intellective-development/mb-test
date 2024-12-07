module Segments
  class StorefrontCommsService < SegmentService
    def initialize(storefront)
      @storefront = storefront
      @comms_handler = Iterable::Storefront::CommsHandler.new(storefront: @storefront)
    end

    def identify(user)
      @comms_handler.user_handler.identify(user)
    end

    def identify_gift_card_recipient(email); end

    def identify_gift_order_recipient(order)
      @comms_handler.user_handler.identify_gift_order_recipient(order)
    end

    def identify_email_capture(email, user)
      @comms_handler.user_handler.identify_email_capture(email, user)
    end

    def sms_identify(user, phone)
      @comms_handler.user_handler.sms_identify(user, phone)
    end

    def track_email_capture(email, user)
      @comms_handler.user_event_handler.track_email_capture(email, user)
    end

    def sms_track(user, phone)
      @comms_handler.user_event_handler.sms_track(user, phone)
    end

    def zipcode_covered_event(user, promotion_type); end

    def delivery_service_update(shipment, event, delivery_service_name = nil, reference_id = nil)
      @comms_handler.shipment_event_handler.delivery_service_update(shipment, event, delivery_service_name, reference_id)
    end

    def order_tracking_updated(package, subtag, subtag_message, gift_individual = :other)
      @comms_handler.package_event_handler.order_tracking_updated(package, subtag, subtag_message, gift_individual)
    end

    def gift_order_tracking_updated(package, subtag, subtag_message)
      order_tracking_updated(package, subtag, subtag_message, :sender)
      order_tracking_updated(package, subtag, subtag_message, :recipient)
    end

    def order_cancelled(order)
      @comms_handler.order_event_handler.order_cancelled(order)
      order_refunded(order)
      products_refunded(order)
    end

    def order_refunded(order)
      @comms_handler.order_event_handler.order_refunded(order)
    end

    def order_fulfilled(order)
      @comms_handler.order_event_handler.order_fulfilled(order)
    end

    def order_finalized(order)
      @comms_handler.order_event_handler.order_finalized(order)
    end

    def order_created(order, gift_individual = :other)
      @comms_handler.order_event_handler.order_created(order, gift_individual)
      products_ordered(order)
    end

    def gift_order_created(order)
      return false unless order.gift?

      order_created(order, :sender)
    end

    def gift_order_received(order)
      return false unless order.gift?

      order_created(order, :recipient)
    end

    def video_gift_order_created(order)
      return false unless order.video_gift_order?

      order_created(order, :sender)
    end

    def order_updated(order, update_type)
      @comms_handler.order_event_handler.order_updated(order, update_type)
    end

    def gift_order_cancelled(order)
      return false unless order.gift?

      order_cancelled(order)
    end

    def video_gift_order_recording_requested(video_gift_message)
      @comms_handler.video_gift_message_event_handler.video_gift_order_recording_requested(video_gift_message)
    end

    def video_gift_order_message_recorded(video_gift_message)
      @comms_handler.video_gift_message_event_handler.video_gift_order_message_recorded(video_gift_message)
    end

    def aging_backorder_notification_created(shipment)
      @comms_handler.shipment_event_handler.aging_backorder_notification_created(shipment)
    end

    def aging_order_notification_created(shipment)
      @comms_handler.shipment_event_handler.aging_order_notification_created(shipment)
    end

    def payment_completed(shipment)
      @comms_handler.shipment_event_handler.payment_completed(shipment)
    end

    def gift_card_purchased(order_item)
      @comms_handler.gift_card_event_handler.gift_card_purchased(order_item)
    end

    def gift_card_received(gift_card, options = {})
      @comms_handler.gift_card_event_handler.gift_card_received(gift_card, options)
    end

    def shipment_processed(package)
      @comms_handler.shipment_event_handler.shipment_processed(package)
    end

    def products_ordered(order)
      @comms_handler.product_event_handler.products_ordered(order)
    end

    def products_refunded(order, order_item = nil)
      @comms_handler.product_event_handler.products_refunded(order, order_item)
    end

    def membership_created(membership)
      @comms_handler.membership_event_handler.membership_created(membership)
    end

    def membership_cancelled(membership)
      @comms_handler.membership_event_handler.membership_cancelled(membership)
    end

    def membership_renewal(membership)
      @comms_handler.membership_event_handler.membership_renewal(membership)
    end

    def membership_payment_completed(membership)
      @comms_handler.membership_event_handler.membership_payment_completed(membership)
    end

    def membership_payment_failed(membership)
      @comms_handler.membership_event_handler.membership_payment_failed(membership)
    end

    def membership_refunded(membership)
      @comms_handler.membership_event_handler.membership_refunded(membership)
    end

    def approval_for_moving_products_between_retailers_requested(old_shipment:, new_order:, approve_url:)
      @comms_handler.customer_response_event_handler.approval_for_moving_products_between_retailers_requested(old_shipment: old_shipment, new_order: new_order, approve_url: approve_url)
    end
  end
end
