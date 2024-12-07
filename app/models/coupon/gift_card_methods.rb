class Coupon
  module GiftCardMethods
    extend ActiveSupport::Concern
    class_methods do
      def sender_email
        order_item.order.email
      end

      def generate_gift_card_code
        Coupons::CouponCodeService.new.generate_code
      end

      def create_gift_card(gift_card_theme, order_item, amount, recipient_email, send_date, sender)
        storefront_id = order_item.shipment.order.storefront_id

        sellable_type = gift_card_theme&.sellable_type
        sellable_ids = gift_card_theme&.sellable_ids

        CouponDecreasingBalance.create(
          order_item: order_item,
          recipient_email: recipient_email,
          code: Coupon.generate_gift_card_code,
          sellable_type: sellable_type,
          sellable_ids: sellable_ids,
          starts_at: Time.zone.now,
          expires_at: 7.years.from_now,
          active: true,
          reporting_type_id: 1,
          free_delivery: false,
          combine: true,
          quota: nil,
          single_use: false,
          minimum_value: 0.0,
          amount: amount,
          description: "Gift card from #{sender}",
          restrict_items: false,
          send_date: send_date,
          skip_fraud_check: true, # TECH-3477
          storefront_id: storefront_id,
          exclude_pre_sale: false
        )
      end
    end

    def deliver!
      CustomerNotifier.gift_card(id).deliver_now unless Feature[:gift_card_email_on_iterable].enabled?
      update(delivered: true)
    end

    def get_delivery_date
      deliver_date = send_date + 10.hours
      if deliver_date < Time.now
        # we need to run the identify (SendGiftCardAnalytics) first
        deliver_date = 3.minutes.from_now
      end
      deliver_date
    end

    def gift_card?
      order_item&.gift_card?
    end

    def change_code!
      self.code = Coupon.generate_gift_card_code
      # we are changing the code so we need to mark as not delivered
      self.delivered = false
      save!
    end

    def change_recipient_email_and_code!(new_email)
      self.recipient_email = new_email
      self.code = Coupon.generate_gift_card_code
      # we are changing the code and the recipient so we need to mark as not delivered
      self.delivered = false
      save!
    end
  end
end
