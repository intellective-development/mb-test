module Coupons
  module DecreasingBalance
    class AddToOrder
      attr_reader :order, :coupon_code, :user

      def initialize(order:, coupon_code:)
        @order = order
        @coupon_code = coupon_code
      end

      def call
        apply_gift_card_to_order
      end

      private

      attr_reader :suppliers_coupon_amount, :business_coupon_amount

      def apply_gift_card_to_order
        validate_gift_card_application

        order.add_gift_card!(gift_card)

        calculate_gift_card_amounts

        gift_card_amount = suppliers_coupon_amount.sum { |_index, value| value } + business_coupon_amount
        order.create_coupon_adjustment_and_update_amounts!(coupon: gift_card, amount: gift_card_amount, debit: true)
      end

      def validate_gift_card_application
        # Order already paid with GC
        raise GiftCardException::AlreadyCoveredError if order.taxed_total.to_f.zero?

        # GC purchases can't use GC
        raise GiftCardException::DigitalOrderError if order.digital?

        raise GiftCardException::InvalidCodeError unless gift_card

        raise GiftCardException::ZeroBalanceError if gift_card.balance.zero?
      end

      def calculate_gift_card_amounts
        @suppliers_coupon_amount = {}
        @supplier_coupon_amount = 0.0
        @business_coupon_amount = 0.0

        supplier_charges = order.shipments.sum(&:total_supplier_charge)
        gift_card_supplier_charges = gift_card.balance > supplier_charges ? supplier_charges : gift_card.balance

        order.shipments.each do |shipment|
          @suppliers_coupon_amount[shipment.id] = ValueSplitter
                                                  .new(gift_card_supplier_charges, limit: shipment.total_supplier_charge)
                                                  .split(supplier_charges, shipment.total_supplier_charge)
        end

        return unless gift_card.balance > supplier_charges

        business_charges = order.service_fee_after_discounts + order.video_gift_fee + order.amounts.membership_tax + order.shipments.sum(&:total_minibar_charge)
        remaining_balance = gift_card.balance - supplier_charges
        @business_coupon_amount = remaining_balance > business_charges ? business_charges : remaining_balance
      end

      def gift_card
        @gift_card ||= Coupon.find_active_gift_card_by_code(coupon_code, order.storefront)
      end
    end
  end
end
