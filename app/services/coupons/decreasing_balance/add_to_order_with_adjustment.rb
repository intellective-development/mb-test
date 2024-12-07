module Coupons
  module DecreasingBalance
    class AddToOrderWithAdjustment < AddToOrder
      attr_reader :order, :coupon_code, :user

      def initialize(order:, coupon_code:, user:)
        @order = order
        @coupon_code = coupon_code
        @user = user
      end

      def call
        apply_gift_card_to_order

        create_adjustment_service_for_shipment
        create_adjustment_service_for_business if business_coupon_amount.positive?
      end

      private

      def create_adjustment_service_for_shipment
        order.shipments.each do |shipment|
          create_adjustment_service(shipment, suppliers_coupon_amount[shipment.id], false)
        end
      end

      def create_adjustment_service_for_business
        shipment = order.shipments.min_by(&:id)
        create_adjustment_service(shipment, business_coupon_amount, true)
      end

      def create_adjustment_service(shipment, amount, business_adjustment)
        order_adjustment_params = default_adjustment_params.merge(amount: amount)
        create_service = OrderAdjustmentCreationService.new(shipment, order_adjustment_params, business_adjustment)

        if create_service.process!
          shipment.save!
          Segment::SendOrderUpdatedEventWorker.perform_async(order.id, :gift_card_applied)
        else
          # This should basically never happen, so I'm just showing the error to MB
          order_adjustment = create_service.error_record

          Rails.logger.error("Gift Card Error: OrderAdjustmentError - #{order_adjustment&.errors&.to_json}")
          raise GiftCardException::OrderAdjustmentError
        end
      end

      def default_adjustment_params
        financial = order.charges.any? || order.order_charges.any?
        {
          reason_id: OrderAdjustmentReason.find_by_name('Discount - Covered by Minibar For Failed Promo').id,
          description: "Customer could not apply code '#{coupon_code.upcase}', applying now.",
          credit: true,
          financial: financial,
          user_id: user.id,
          braintree: true
        }
      end
    end
  end
end
