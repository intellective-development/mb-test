# frozen_string_literal: true

module SupplierSwitchingForOosProducts
  # SupplierSwitchingForOosProducts::CreateOrderService
  class CreateOrderService < BaseService
    include SentryNotifiable

    class OrderItemCandidatesEmptyError < ArgumentError; end
    class OrderItemCandidatesKeysInvalidError < ArgumentError; end
    class OldShipmentNotFound < ArgumentError; end

    attr_reader :error

    def initialize(old_shipment_uuid:, order_item_candidates:)
      super

      @order_item_candidates = Array(order_item_candidates)

      raise OrderItemCandidatesEmptyError, 'Order item candidates cannot be blank or empty' if @order_item_candidates.blank?

      @order_item_candidates = @order_item_candidates.map(&:stringify_keys)
      @order_item_candidates.each do |oi|
        raise OrderItemCandidatesKeysInvalidError, "Order items should contain hashes with 'variant_id' and 'quantity' keys" unless %w[variant_id quantity].all? { |key| oi.key?(key) }
      end

      @old_shipment = Shipment.find_by(uuid: old_shipment_uuid)

      raise OldShipmentNotFound, "Shipment with uuid #{old_shipment_uuid} not found" if @old_shipment.nil?

      @user = old_order.user
      @storefront = old_order.storefront
    end

    def call
      ActiveRecord::Base.transaction do
        create_order
        link_old_new_orders
        create_comment_for_manual_approval
        credit_price_difference_to_new_supplier_monthly_invoice
        send_comms
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

    def create_order
      @order = @user.orders.new(storefront: @storefront)

      params = {
        email: @user.email,
        shipping_address_id: @old_shipment.address,
        payment_profile_id: old_order.payment_profile_id,
        delivery_method_id: @old_shipment.shipping_method_id,
        birthdate: old_order.birthdate,
        order_items: build_order_items
      }

      order_service = OrderCreationServices.new(@order, @user, nil, params, skip_scheduling_check: true, skip_in_stock_check: false)
      order_service.build_order

      MetricsClient::Metric.emit('order.storefront.id', @order.storefront.id)

      @order.save!
      @order.order_amount&.save!

      calculate_order_taxes

      apply_deals if @order.minibar?
      apply_coupon_for_oos_amount_covered_by_storefront

      unless order_service.valid?
        @order.cancel_finalize

        raise CreateOrUpdateOrderError, order_service.error_args.first.to_json
      end

      @order.save!
    end

    def link_old_new_orders
      old_order.comments.create!(note: "The supplier for shipment with uuid '#{@old_shipment.uuid}' was switched. Here's the new order that was created: #{@order.number}")
    end

    def create_comment_for_manual_approval
      old_order.comments.create!(note: "Manual approval URL for shipment ##{@old_shipment.uuid}: #{approve_url}")
    end

    def send_comms
      SupplierSwitchingForOosProducts::SendApprovalRequestedEventWorker.perform_async(@old_shipment.id, @order.id, approve_url)
    end

    def approve_url
      SupplierSwitchingForOosProducts::CreateOrderApproveUrlService.call(order_id: @order.id)
    end

    def build_order_items
      @order_item_candidates.map do |oi|
        {
          variant_id: oi['variant_id'],
          quantity: oi['quantity']
        }
      end
    end

    def calculate_order_taxes
      @order.reload
      @order.recalculate_and_apply_taxes(order_ship_address)

      @order.save!
    end

    def apply_deals
      deal_service = Deals::ApplyDealsService.new(@order)
      deal_service.call

      MetricsClient::Metric.emit('minibar_web.orders.errors.deal_service_error', 0)
    rescue StandardError => e
      MetricsClient::Metric.emit('minibar_web.orders.errors.deal_service_error', 1)
      notify_sentry_and_log(e, "Error calling deals service #{e.message}", { tags: { order_id: @order.id } })

      raise e
    end

    def apply_coupon_for_oos_amount_covered_by_storefront
      return if amount_to_be_covered_by_storefront.zero?

      @order.add_coupon(coupon_for_oos_amount_covered_by_storefront)
      @order.recalculate_and_apply_taxes(order_ship_address)

      @order.save!
    end

    def credit_price_difference_to_new_supplier_monthly_invoice
      return if amount_to_be_covered_by_storefront.zero?

      reason = OrderAdjustmentReason.find_by(name: 'Money Owed to Store from Minibar* (This is a 2nd OA only)', owed_to_supplier: true)

      @order.shipments.each do |s|
        s.order_adjustments.create!(reason: reason, amount: amount_to_be_covered_by_storefront, credit: true, description: 'Storefront OOS Amount Coverage')
      end
    end

    def coupon_for_oos_amount_covered_by_storefront
      return if amount_to_be_covered_by_storefront.zero?

      CouponValue.create!(
        quota: 1,
        active: true,
        free_service_fee: true,
        amount: amount_to_be_covered_by_storefront,
        starts_at: DateTime.current,
        storefront: @order.storefront,
        code: CouponValue.generate_code,
        description: 'Storefront OOS Amount Coverage'
      )
    end

    def amount_to_be_covered_by_storefront
      return @amount_to_be_covered_by_storefront if defined?(@amount_to_be_covered_by_storefront)

      price_diff = @order.taxed_total.to_f - @old_shipment.total_amount.to_f
      storefront_oos_amount_willing_to_cover = @order.storefront.oos_amount_willing_to_cover

      @amount_to_be_covered_by_storefront = if price_diff.negative?
                                              0.0
                                            elsif price_diff < storefront_oos_amount_willing_to_cover
                                              price_diff
                                            else
                                              storefront_oos_amount_willing_to_cover
                                            end.to_f.round_at(2)
    end

    def old_order
      @old_order ||= @old_shipment.order
    end

    def order_ship_address
      @order_ship_address ||= @order.ship_address
    end
  end
end
