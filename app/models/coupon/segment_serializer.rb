class Coupon
  module SegmentSerializer
    def gift_card_image_url
      return unless order_item.present?

      if (gc_image = order_item.item_options&.gift_card_image)
        gc_image.image_url
      else
        order_item.variant.product.featured_image(:original)
      end
    end

    def recipient_segment_id
      Digest::SHA256.hexdigest(String(recipient_email).downcase)
    end

    def html_recipient_message
      order_item.item_options.message.gsub("\n", '<br/>') if order_item.item_options.message.present?
    end

    def gift_card_send_immediately
      send_date == Date.today
    end

    def as_segment_gift_card(options = {})
      {
        value: amount.to_f,
        code: code.upcase,
        imageUrl: gift_card_image_url,
        message: html_recipient_message,
        from: order_item.item_options.sender,
        sendDate: send_date,
        sendImmediately: options['send_immediately'] || gift_card_send_immediately,
        correction: options['correction'] ? true : false
      }
    end
  end
end
