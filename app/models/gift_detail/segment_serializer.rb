class GiftDetail
  module SegmentSerializer
    extend ActiveSupport::Concern
    def as_segment_object
      most_relevant_shipment = order.segment_most_relevant_shipment
      segment_delivery_date = most_relevant_shipment.segment_delivery_date
      {
        recipient_name: recipient_name,
        recipient_email: recipient_email,
        recipient_phone: recipient_phone,
        order_number: order.number,
        delivery_details: order.ship_address.as_segment_address,
        message: html_recipient_message,
        total_shipments: order.shipments.count,
        send_date: segment_delivery_date,
        send_immediately: segment_delivery_date == Date.today,
        shipments: order.shipments_as_segment_object(segment_delivery_date),
        sender_name: order.user.name
      }
    end

    def as_segment_recipient
      {
        user_id: recipient_segment_id,
        traits: {
          email: recipient_email,
          name: recipient_name,
          phone: recipient_phone
        }
      }
    end

    def html_recipient_message
      message.gsub("\n", '<br/>')
    end

    def recipient_segment_id
      Digest::SHA256.hexdigest(String(recipient_email).downcase)
    end
  end
end
