# frozen_string_literal: true

module OrderItems
  # OrderItems::Remove
  class Remove < BaseService
    attr_reader :error

    def initialize(order_item:, user:, quantity: nil)
      raise ArgumentError, 'Order item cannot be nil' if order_item.nil?

      @order_item = order_item
      @user = user
      @order = @order_item.order
      @shipment = @order_item.shipment
      @quantity = quantity

      raise ArgumentError, 'Order item\'s quantity is lower than the quantity that was passed' if @quantity.present? && @order_item.quantity < @quantity
    end

    def call
      if eligible_for_shipment_cancellation?
        cancel_shipment
      else
        remove_item
        send_comms if success?
      end

      self
    end

    def success?
      @error.nil?
    end

    private

    def eligible_for_shipment_cancellation?
      return @shipment.reload.order_items.one? if @quantity.nil?

      @shipment.reload.order_items.one? && @order_item.quantity == @quantity
    end

    def cancel_shipment
      reason = OrderAdjustmentReason.find_by(name: 'Order Change - Item Removed from Order (Not OOS, Customer Requested)')
      params = { order_adjustment: { reason_id: reason&.id, description: 'Order Change - Item Removed from Order (Not OOS, Customer Requested)' } }

      begin
        result = Shipment::Cancellations::Create.new(shipment: @shipment, user: @user, params: params).call
        @error = shipment_cancellation_error(result.error) unless result.success?
      rescue ArgumentError => e
        @error = shipment_cancellation_error(e.message)
      end
    end

    def remove_item
      @shipment.remove_order_item(@order_item, @user.id, @quantity)
      @order.reload.bar_os_order_send!(:update_line_items)
    rescue StandardError => e
      @error = order_item_removal_error(e.message)
    end

    def send_comms
      Segment::SendOrderUpdatedEventWorker.perform_async(@order.id, :item_removed)
      Segment::SendProductsRefundedEventWorker.perform_async(@order.id, @order_item.id)
    end

    def order_item_removal_error(error_message)
      "OrderItemRemovalError: #{error_message}"
    end

    def shipment_cancellation_error(error_message)
      "ShipmentCancellationError: #{error_message}"
    end
  end
end
