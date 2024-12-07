class Coupon::ShipmentGiftCardRefundWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find shipment_id
    order = shipment.order
    amount_to_refund = shipment.shipment_coupon_amount

    return if amount_to_refund.to_f.zero?

    order.all_gift_card_coupons.each do |gift_card|
      coupon_balance = gift_card.balance_for_order(order)
      next unless coupon_balance.positive?

      gift_card_refund = 0
      if coupon_balance >= amount_to_refund
        gift_card_refund = amount_to_refund
        amount_to_refund = 0
      else
        gift_card_refund = coupon_balance
        amount_to_refund -= coupon_balance
      end
      Coupon::CreateBalanceAdjustmentWorker.perform_async(gift_card.id, order_id: order.id, debit: false, amount: gift_card_refund) if gift_card_refund.positive?
    end
  end
end
