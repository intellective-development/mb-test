class ExternalAPIV1::Entities::Order < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :number
  expose :state
  expose :display_state

  expose :shipments, with: ExternalAPIV1::Entities::Shipment do |order|
    order.shipments.includes(:shipping_method, :supplier, :order_items, :packages, :comments, :tracking_detail)
  end

  expose :comments, with: Shared::Entities::Comment
  expose :shipping_method_types, if: ->(instance, _options) { instance.completed_at } do |order|
    order.shipping_methods.map(&:shipping_type).uniq
  end

  expose :completed_at, if: ->(instance, _options) { !instance.completed_at.nil? }, format_with: :iso_timestamp
  expose :status_actions, if: ->(instance, _options) { Order::TRACKABLE_STATES.include?(instance.state) }, with: ExternalAPIV1::Entities::Shipment::StatusAction

  expose :gift_options, if: ->(instance, _options) { instance.gift? } do
    expose :gift_message,         as: :message
    expose :gift_recipient,       as: :recipient_name
    expose :gift_recipient_phone, as: :recipient_phone
    expose :gift_recipient_email, as: :recipient_email
  end

  expose :created_at
  expose :scheduled
  expose :scheduled_for, format_with: :iso_timestamp
  expose :allow_substitution

  private

  def display_state
    if object.confirmed? && object.confirmed_at && object.confirmed_at < 6.hours.ago
      'delivered'
    elsif object.verifying?
      'paid'
    else
      object.state
    end
  end

  def status_actions
    object.shipments.select { |shipment| shipment.shipping_method&.trackable? }
  end

  def gift_message
    object.gift_detail.message
  end

  def gift_recipient
    object.gift_detail.recipient_name
  end

  def gift_recipient_phone
    object.gift_detail.recipient_phone
  end

  def gift_recipient_email
    object.gift_detail.recipient_email
  end

  def created_at
    object.created_at.strftime('%B %d %Y %H:%M %P (%Z)')
  end

  def scheduled
    object.scheduled_for.present?
  end
end
