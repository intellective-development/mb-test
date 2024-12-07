# Create a Coupon when a GiftCard is purchased
#
class Shipment::CreateGiftCardWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)

    shipment.order_items.gift_card.each do |gift_card_item|
      gift_card_theme = gift_card_item.product_size_grouping.gift_card_theme

      gift_card_item.recipients.each do |recipient|
        email_coupons = gift_card_item.recipients.select { |r| r == recipient }.count

        next unless Coupon.where(order_item: gift_card_item, recipient_email: recipient).count < email_coupons

        send_date = [gift_card_item.item_options.send_date, Time.zone.today].max

        c = Coupon.create_gift_card(gift_card_theme, gift_card_item, gift_card_item.price, recipient, send_date, gift_card_item.item_options.sender)

        order = shipment.order

        if order.video_gift_order? && order.digital?
          Coupon::DeliverGiftCardWorker.perform_async(c.id)
        else
          Coupon::DeliverGiftCardWorker.perform_at(c.get_delivery_date, c.id)
        end
      end
    end
    Coupon::SendGiftCardAnalytics.perform_async(shipment_id)
  end
end
