class OrderItem
  module SegmentSerializer
    def as_segment_gift_card_purchase
      {
        value: price.to_f,
        recipients: recipients,
        sendDate: send_date,
        total_count: recipients.count,
        total_amount: (recipients.count * price).round(2).to_f
      }
    end
  end
end
