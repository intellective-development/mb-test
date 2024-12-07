# frozen_string_literal: true

module SupplierSwitchingForOosProducts
  # SupplierSwitchingForOosProducts::FinalizeOrderService
  class FinalizeOrderService < BaseService
    include SentryNotifiable

    attr_reader :error

    def initialize(order_id:)
      super

      @order = Order.find(order_id)
    end

    def call
      ActiveRecord::Base.transaction do
        finalize_order
      rescue StandardError => e
        notify_sentry_and_log(e)

        @error = e.message

        raise ActiveRecord::Rollback
      end

      self
    end

    def success?
      @error.nil?
    end

    private

    attr_accessor :order

    def finalize_order
      @order.finalize! unless @order.finalizing?

      finalize = ::FinalizeOrderService.new(@order)

      return if @order.consider_paid? && @order.shipments.pending.empty?

      if finalize.process
        if @order.order_amount
          @order.order_amount.skip_coupon_creation = false
          @order.order_amount.create_balance_adjustment
        end
      else
        @order.cancel_finalize!

        message = order_finalize_error_message(finalize.errors)
        Rails.logger.warn("Order cannot be finalized. #{message}")

        @error = message
      end
    rescue StandardError => e
      message = order_finalize_error_message(finalize&.errors)
      notify_sentry_and_log(e, "Order cannot be finalized. #{message}", { tags: { order_id: @order.id }, extra: { errors: finalize&.errors&.values&.flatten } })

      @order.cancel_finalize! if @order.finalizing?

      raise e, message
    end

    def order_finalize_error_message(errors)
      errors.blank? ? 'Unable to finalize order.' : errors.values.flatten.to_sentence
    end
  end
end
