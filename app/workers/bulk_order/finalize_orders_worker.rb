class BulkOrder::FinalizeOrdersWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include BulkOrderDataCsv
  include Shared::Helpers::OrderEndpointHelpers
  include Shared::Helpers::FraudHelpers

  sidekiq_options queue: 'bulk_order', lock: :until_and_while_executing, retry: 3

  attr_reader :params

  delegate :storefront, to: :@bulk_order

  def fraud_options(_ignore, _also_ignore)
    {}
  end

  def error!(msg, _status)
    raise StandardError, msg
  end

  def finalize_orders(bulk_order_id)
    Rails.logger.info("Finalizing bulk order #{bulk_order_id}")

    @bulk_order = BulkOrder.find(bulk_order_id)

    # only let finalize if active. otherwise, it's already been finalized or in progress
    return unless @bulk_order.active? || @bulk_order.finalizing?

    @bulk_order.bulk_order_orders.each do |bulk_order_order|
      bulk_order_order.order_errors = nil
      @order = bulk_order_order.order

      next unless @order.in_progress?

      @user = @order.user
      @cart = @order.cart
      @params = { cart_id: @cart.id }
      @params[:gift_cards] = [@bulk_order.coupon&.code] if @bulk_order.coupon&.code.present?

      @order.finalize! unless @order.finalizing?

      begin
        create_or_update_order(skip_scheduling_check: false)
        @order.save!
        do_finalize
      rescue StandardError => e
        Rails.logger.error("Error finalizing order: #{e.message}")
        bulk_order_order.update_attribute(:order_errors, "Error finalizing order. Check your payment details. #{e.message}")
        @order.cancel_finalize! if @order.finalizing?
        next
      end
    end

    @bulk_order.finalized!
    @bulk_order.save
  rescue StandardError => e
    Rails.logger.error("Error finalizing bulk order #{bulk_order_id}: #{e.message}")
    @bulk_order.active!
    raise e
  end

  def perform_with_error_handling(bulk_order_id)
    finalize_orders(bulk_order_id)
  end
end
