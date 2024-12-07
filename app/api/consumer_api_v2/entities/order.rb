class ConsumerAPIV2::Entities::Order < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :number
  expose :storefront_uuid
  expose :storefront, with: ConsumerAPIV2::Entities::Storefront
  expose :order_state, as: :state
  expose :display_state
  expose :birthdate
  expose :new_buyer_candidate
  expose :order_items, with: ConsumerAPIV2::Entities::OrderItem do |order|
    order.order_items.group_by { |item| item.identifier&.to_i || item.variant_id }.to_a
  end

  expose :shipping_method_types, if: ->(instance, _options) { instance.completed_at } do |order|
    order.shipping_methods.map(&:shipping_type).uniq
  end

  expose :completed_at, if: ->(instance, _options) { !instance.completed_at.nil? }, format_with: :iso_timestamp
  expose :amounts do |object, _options|
    ConsumerAPIV2::Entities::Amounts.represent(object)
  end

  expose :qualified_deals
  expose :gift_cards do |order|
    order.coupons.coupon_decreasing_balance.map(&:code)
  end
  expose :promo_codes do |order|
    order.coupons.non_gift_card.map(&:code)
  end
  expose :coupon_code, as: :promo_code do |order|
    order.coupon.present? ? String(order.coupon_code).upcase : nil
  end
  expose :coupons do |order|
    order.all_coupons.map(&:code)
  end

  expose :suppliers, if: ->(instance, _options) { !instance.completed_at.nil? }, with: ConsumerAPIV2::Entities::Supplier
  expose :status_actions, if: ->(instance, _options) { Order::TRACKABLE_STATES.include?(instance.state) }, with: ConsumerAPIV2::Entities::OrderStatusAction

  expose :gift_options, if: ->(instance, _options) { instance.gift? } do
    expose :gift_message,         as: :message
    expose :gift_recipient,       as: :recipient_name
    expose :gift_recipient_phone, as: :recipient_phone
    expose :gift_recipient_email, as: :recipient_email
  end

  expose :delivery_notes
  expose :ship_address, as: :shipping_address, if: ->(instance, _options) { instance.shipments.any?(&:on_demand?) || instance.shipments.any?(&:shipped?) }, with: ConsumerAPIV2::Entities::Address
  expose :pickup_detail, if: ->(instance, _options) { instance.shipments.any?(&:pickup?) }, with: ConsumerAPIV2::Entities::PickupDetail
  expose :payment_profile, with: ConsumerAPIV2::Entities::PaymentProfile

  expose :shipments, with: ConsumerAPIV2::Entities::OrderShipment, if: ->(_object, options) { options[:expose_shipments] }
  expose :cart, with: ConsumerAPIV2::Entities::Cart, if: ->(_object, options) { options[:expose_cart] }

  expose :video_gift_message, with: ConsumerAPIV2::Entities::VideoGiftMessage
  expose :video_gift_message_eligible do |order|
    order.storefront.vgm_eligible?
  end

  expose :legacy_rb_paypal_supported
  expose :affirm_supported?, as: :affirm_supported

  expose :membership, with: ConsumerAPIV2::Entities::Membership
  expose :membership_plan, with: ConsumerAPIV2::Entities::MembershipPlan

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

  def qualified_deals
    object.applied_deals.pluck(:title).uniq
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

  def gift_message
    object.gift_detail.message
  end

  def order_state
    options[:override_order_state] || display_state
  end

  def new_buyer_candidate
    object.new_buyer_candidate?
  end

  def legacy_rb_paypal_supported
    object.legacy_rb_paypal_supported?
  end
end
