# frozen_string_literal: true

class Shipment
  module Cancellations
    # Shipment::Cancellations::Create
    class Create
      attr_reader :shipment, :error

      def initialize(shipment:, user:, params:)
        raise ArgumentError, 'Shipment cannot be nil' if shipment.nil?
        raise ArgumentError, 'User cannot be nil' if user.nil?
        raise ArgumentError, 'Shipment was already canceled' if shipment.canceled?

        @shipment = shipment
        @user = user
        @params = params.dup
        @cancellation_fee = order_adjustment_cancellation_fee
      end

      def call
        cancel_shipment

        @shipment = @shipment.reload

        self
      end

      def success?
        @error.nil?
      end

      private

      def cancel_shipment
        attrs = cancel_adjustment_attrs(@shipment, adjustment_params)
        adjustment = @shipment.order_adjustments.new(attrs)
        fee_adjustment = if @cancellation_fee && @cancellation_fee > 0.0
                           fee_attrs = cancellation_fee_adjustment_attrs(@shipment, @cancellation_fee, reason)
                           @shipment.order_adjustments.new(fee_attrs)
                         end

        ActiveRecord::Base.transaction do
          fee_adjustment&.save!
          @shipment.cancel!
          comment = @shipment.order.comments.new(note: "#{@shipment.supplier_name} Shipment was canceled.", created_by: @user&.id)

          @shipment.cancellation_reason_id = adjustment_params[:reason_id]
          @shipment.cancellation_notes = adjustment_params[:description]
          @shipment.save!

          adjustment.save!
          @shipment.save!
          comment.save!

          CancelDeliveryServiceWorker.perform_async(@shipment.id, @shipment.delivery_service.id, false) if @shipment.delivery_service
        rescue StandardError => e
          Rails.logger.error e.message

          @error = e.message

          raise ActiveRecord::Rollback
        end
      end

      def order_adjustment_cancellation_fee
        adjustment_params[:cancellation_fee].to_f if adjustment_params[:cancellation_fee] && adjustment_params[:cancellation_fee].to_f > 0.0
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
          description: adjustment_params[:description],
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
