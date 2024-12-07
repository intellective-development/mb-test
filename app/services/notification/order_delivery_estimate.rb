module Notification
  class OrderDeliveryEstimate
    attr_reader :order, :shipments

    def initialize(order)
      @order = order

      # Currently we only notify for on_demand orders
      @shipments = order.shipments.select(&:on_demand?)
    end

    def perform
      # We don't want to notify the user in the event that a shipment is late,
      # this triggers a separate email/cx flow.
      return false unless should_notify?

      delivery_estimate = order.shipments.first.delivery_estimate&.user_description
      return false if delivery_estimate.blank?

      # Commented this one, even though it works, it's being defined ATM. Check TECH-3794
      # PushNotificationWorker.perform_async(:order_estimate, order.user.email, { estimate: delivery_estimate })
    end

    private

    def should_notify?
      shipments.none?(&:delivery_service_order?) && shipments.all?(&:on_demand?) && !late_shipment?
    end

    def late_shipment?
      shipments.any?(&:determined_late?)
    end
  end
end
