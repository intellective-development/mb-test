# frozen_string_literal: true

class Order
  module Cancellations
    # Order::Cancellations::Create
    class Create
      attr_reader :order, :error

      def initialize(order:, user:, params:)
        raise ArgumentError, 'Order cannot be nil' if order.nil?
        raise ArgumentError, 'User cannot be nil' if user.nil?
        raise ArgumentError, 'Order was already canceled' if order.canceled?

        @order = order
        @user = user
        @params = params.dup
        @cancellation_fee = order_adjustment_cancellation_fee
      end

      def call
        ActiveRecord::Base.transaction do
          cancel_shipments
          cancel_order
          cancel_deliveries
        rescue StandardError => e
          @error = e.message

          raise ActiveRecord::Rollback
        end

        @order = @order.reload

        self
      end

      def success?
        @error.nil?
      end

      private

      def order_adjustment_cancellation_fee
        adjustment_params[:cancellation_fee].to_f if adjustment_params[:cancellation_fee] && adjustment_params[:cancellation_fee].to_f > 0.0
      end

      def cancel_shipments
        adjustments = []

        @order.shipments.includes(:shipping_method, :shipment_amount, :taggings, :supplier).each do |shipment|
          attrs = cancel_adjustment_attrs(shipment, adjustment_params)
          adjustments << shipment.order_adjustments.new(attrs)

          fee_adjustment = if @cancellation_fee && @cancellation_fee > 0.0
                             shipment_cancelation_fee = [@cancellation_fee, shipment.shipment_total_amount].min
                             @cancellation_fee -= shipment_cancelation_fee
                             fee_attrs = cancellation_fee_adjustment_attrs(shipment, shipment_cancelation_fee, reason)
                             shipment.order_adjustments.new(fee_attrs)
                           end

          adjustments << fee_adjustment if fee_adjustment

          shipment.cancellation_reason_id = adjustment_params[:reason_id]
          shipment.cancellation_notes = adjustment_params[:description]
          shipment.save!
        end

        adjustments.map(&:save!)
      end

      def cancel_order
        # if reason is fraud (reason_id) then send over for cancellation and flagging
        @order.order_canceled!(send_confirmation_email: @params[:send_confirmation_email], reason_id: adjustment_params[:reason_id])
        @order.save!
      end

      def cancel_deliveries
        @order.order_suppliers.each do |supplier|
          delivery_service_id = supplier.delivery_service_id
          CancelDeliveryServiceWorker.perform_async(@order.id, delivery_service_id) unless delivery_service_id.nil?
        end
      end

      def adjustment_params
        @adjustment_params ||= ActionController::Parameters.new(@params[:order_adjustment]).permit(:reason_id, :description, :cancellation_fee)
      end

      def reason
        @reason ||= OrderAdjustmentReason.find_by(name: 'Cancellation Fee')
      end

      def cancel_adjustment_attrs(shipment, adjustment_params)
        {
          user_id: @user&.id,
          shipment_id: shipment.id,
          reason_id: adjustment_params[:reason_id],
          description: adjustment_params[:description].presence,
          financial: false,
          braintree: false,
          credit: 0.0,
          amount: 0.0
        }
      end

      def cancellation_fee_adjustment_attrs(shipment, amount, reason)
        {
          user_id: @user&.id,
          shipment_id: shipment.id,
          reason_id: reason&.id,
          description: 'Supplier cancellation fee',
          financial: true,
          braintree: true,
          credit: false,
          amount: amount
        }
      end
    end
  end
end
