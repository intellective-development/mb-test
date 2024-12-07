class InternalNotificationService
  class << self
    def notify(params, _skip_slack: false, skip_asana: false)
      InternalAsanaNotificationWorker.perform_async(params) unless skip_asana
    end

    def notify_order_address_is_blacklisted(order)
      blacklist_reason = AddressBlacklist.blacklist_reason(order.ship_address)
      notification_params = {
        name: "Order #{order.number} must be canceled - #{order.user_name}",
        notes: "Cancel order immediately: #{blacklist_reason}.\n\nOrder: #{link_to_order(order)}",
        projects: [AsanaService::PROJECT_ID]
      }
      notify(notification_params)
    end

    def notify_order_is_corporate(order)
      notification_params = {
        name: "Order #{order.number} is corporate - #{order.user_name}",
        notes: "Customer email is #{order.user.email}, purchased more than $50 and is not tagged as corporate.\n\nOrder: #{link_to_order(order)}",
        projects: [AsanaService::CORPORATE_ORDERS_PROJECT_ID]
      }
      notify(notification_params)
    end

    def notify_30_min_passed_and_no_driver_picked(shipment)
      order = shipment.order
      notification_params = {
        name: "Order #{order.number} has no driver after 30 mins - #{order.user_name}",
        notes: "Order hasn't had a driver selected after 30 mins. Delivery service is #{shipment.supplier&.delivery_service&.name}.\n\nOrder: #{link_to_order(order)}",
        projects: [AsanaService::PROJECT_ID]
      }
      notify(notification_params)
    end

    def notify_order_needs_gift_card_image_review(order)
      notification_params = {
        name: "Order #{order.number} needs gift card image review - #{order.user_name}",
        notes: "Order has one or more custom gift card images that needs review and confirmation.\n\nOrder: #{link_to_order(order)}",
        projects: [AsanaService::PROJECT_ID],
        tags: [AsanaService::CUSTOM_GIFT_CARD_TAG_ID]
      }
      notify(notification_params)
    end

    def notify_recent_gc_redeemed_for_isp(order)
      new_gift_cards = order.all_gift_card_coupons.select { |c| c.created_at >= 1.hour.ago }.map(&:code).join(', ')
      notification_params = {
        name: "Order #{order.number} is ISP and used a new gift card - #{order.user_name}",
        notes: "Order is ISP and used these newly purchased (< 1 hr) gift cards: #{new_gift_cards}.\n\nOrder: #{link_to_order(order)}",
        projects: [AsanaService::RECENT_GIFT_CARD_ISP]
      }
      notify(notification_params)
    end

    def link_to_order(order)
      "#{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{order.number}/edit"
    end
  end
end
