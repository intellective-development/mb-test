# rubocop:disable Style/HashEachMethods
class Shipment::GiftCardUpdaterService
  attr_accessor :shipment, :params, :errors

  def initialize(shipment, params, current_user)
    @shipment = shipment
    @params = params
    @current_user = current_user
    @segment_service = Segments::SegmentService.from(@shipment.order.storefront)
    @errors = []
  end

  def process!
    order_items_attrs = params[:order_items_attributes]

    coupons_to_delete = []
    to_resend = []
    cc_sender_order_item_ids = []

    order_items_attrs.values.each do |order_item_attrs|
      order_item = OrderItem.find order_item_attrs[:id]
      item_options_attrs = order_item_attrs[:item_options_attributes]
      coupons_attrs = order_item_attrs[:coupons_attributes]

      # if order is on verifying state we don't do any updates
      next if coupons_attrs.nil?

      coupons_attrs.values.each do |coupon_attrs|
        coupon = Coupon.find coupon_attrs['id']

        if coupon_attrs['deleted'] == '1' && !coupon.expired?
          coupons_to_delete << coupon_attrs['id']
          next
        end

        next if coupon.recipient_email == coupon_attrs['recipient_email']

        update_gift_card_recipient(coupon, coupon_attrs['recipient_email'])
      end

      if coupons_to_delete.size == order_item.quantity
        @errors << 'You cannot delete all gift cards'
        return false
      end

      delete_gift_cards(order_item, coupons_to_delete)

      item_options = order_item.item_options
      item_options.message = item_options_attrs[:message]
      new_send_date = Date.parse(item_options_attrs[:new_send_date])
      item_options.recipients = gift_card_recipient_emails_from_coupons(order_item.id)

      change_deliver_date(order_item, item_options, new_send_date) if new_send_date != item_options.send_date

      if item_options_attrs[:resend] == '1'
        coupons = Coupon.not_expired(Time.zone.now).where(order_item_id: order_item.id).to_a
        to_resend += coupons.reject(&:redeemed?).pluck(:id) if coupons[0].delivered
      end

      cc_sender_order_item_ids << order_item.id if item_options_attrs[:cc_sender] == '1'

      item_options.save!
      item_options.generate_report
    end

    Coupon::GiftCardSummaryWorker.perform_at(3.minutes.from_now, cc_sender_order_item_ids) if cc_sender_order_item_ids.any?

    resend_gift_cards(to_resend)
    true
  end

  def change_deliver_date(order_item, item_options, new_send_date)
    item_options.send_date = new_send_date
    coupons = Coupon.not_expired(Time.zone.now).where(order_item: order_item)
    coupons.each do |coupon|
      coupon.send_date = new_send_date
      if !coupon.delivered
        coupon.save
      else
        coupon.change_code!
      end
      Coupon::DeliverGiftCardWorker.perform_at(coupon.get_delivery_date, coupon.id)
    end
  end

  def update_gift_card_recipient(coupon, new_email)
    old_email = coupon.recipient_email
    # we need to re-deliver if it was already delivered....
    Coupon::DeliverGiftCardWorker.perform_at(coupon.get_delivery_date, coupon.id) if coupon.delivered
    coupon.change_recipient_email_and_code!(new_email)
    @segment_service.identify_gift_card_recipient(old_email)
    @segment_service.identify_gift_card_recipient(coupon.recipient_email)
  end

  def delete_gift_cards(order_item, coupons_to_delete)
    unless coupons_to_delete.empty?
      @shipment.remove_order_item(order_item, @current_user.id, coupons_to_delete.size)
      coupons_to_delete.each do |coupon_id|
        coupon = Coupon.find coupon_id
        coupon.expire!
        @segment_service.gift_card_expired(coupon)
        @segment_service.identify_gift_card_recipient(coupon.recipient_email)
      end
    end
  end

  def deliver_gift_cards(coupon_ids)
    Coupon.where(id: coupon_ids.uniq).each do |coupon|
      Coupon::DeliverGiftCardWorker.perform_in(1.minute, coupon.id, resend: true)
    end
  end

  def resend_gift_cards(coupon_ids)
    Coupon.where(id: coupon_ids.uniq).each do |coupon|
      Coupon::DeliverGiftCardWorker.perform_in(1.minute, coupon.id, resend: true)
    end
  end

  def email_items_hash
    @shipment.order_items.gift_card.map { |oi| [oi.id, oi.item_options.recipients] }.to_h
  end

  def gift_card_recipient_emails_from_coupons(order_item_id)
    Coupon.not_expired(Time.zone.now).where(order_item_id: order_item_id).pluck(:recipient_email)
  end
end
# rubocop:enable Style/HashEachMethods
