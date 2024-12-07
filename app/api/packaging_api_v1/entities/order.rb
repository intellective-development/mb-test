class PackagingAPIV1::Entities::Order < Grape::Entity
  expose :number
  expose :created_at
  expose :customer_name

  expose :shipments, with: PackagingAPIV1::Entities::Order::Shipment
  expose :video_gift_message, with: PackagingAPIV1::Entities::Order::VideoGiftMessage

  expose :gift_options do
    expose :gift_message, as: :message
    expose :gift_recipient, as: :recipient_name
  end

  expose :is_gift, &:gift?

  private

  def gift_message
    object.gift_detail&.message
  end

  def gift_recipient
    object.gift_detail&.recipient_name
  end

  def customer_name
    object.user_name
  end
end
