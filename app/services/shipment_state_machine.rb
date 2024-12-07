class ShipmentStateMachine
  include Statesman::Machine
  include Statesman::Events

  COMPLETED_STATES = %w[delivered canceled].freeze
  INVOICABLE_STATES = %w[confirmed scheduled en_route delivered ready_to_ship paid accepted].freeze
  SUPPLIER_TODAY_VISIBLE_STATES = %w[paid confirmed en_route canceled accepted].freeze
  SUPPLIER_TODAY_SHIPPED_VISIBLE_STATES = %w[paid confirmed canceled accepted].freeze
  SUPPLIER_VISIBLE_STATES = %w[paid confirmed scheduled canceled exception en_route delivered ready_to_ship pre_sale back_order accepted].freeze
  UNCONFIRMED_STATES = %w[paid ready_to_ship].freeze
  SHIPPING_STATES = %w[paid confirmed scheduled ready_to_ship].freeze
  AGING_ORDER_NOTIFICATION_IGNORED_STATES = %w[pending canceled delivered back_order en_route ready_to_ship pre_sale accepted exception].freeze
  OVERVIEWS_STATES = %w[ready_to_ship confirmed delivered en_route scheduled pre_sale back_order exception accepted paid].freeze

  state :pending, initial: true # Shipment has been created but not yet paid.
  state :back_order             # Shipment has not been paid and not yet confirmed.
  state :pre_sale               # Shipment has not been paid and not yet confirmed.
  state :paid                   # Shipment has been charged. Is now visible to supplier.
  state :confirmed              # Shipment has been confirmed by supplier.
  state :scheduled              # Shipment has been scheduled for a future date.
  state :canceled               # Shipment has been canceled.
  state :exception              # There is a problem that requires resolution.
  state :en_route               # Delivery has begun. Shipment has left the supplier.
  state :delivered              # Shipment has been delivered.
  state :accepted               # Shipment has been accepted.
  state :test                   # Shipment is a test shipment. (canceled and must not appear on supplier's dashboard)
  state :staggered              # Shipment has been marked for delayed charge.

  event :set_as_pre_sale do
    transition from: :pending,    to: :pre_sale
    transition from: :exception,  to: :pre_sale
  end

  event :set_as_back_order do
    transition from: :pending,    to: :back_order
    transition from: :exception,  to: :back_order
  end

  event :set_as_staggered! do
    transition from: :pending,    to: :staggered
    transition from: :exception,  to: :staggered
  end

  event :pay do
    transition from: :pending,    to: :paid
    transition from: :staggered,  to: :paid
    transition from: :back_order, to: :paid
    transition from: :pre_sale,   to: :paid
    transition from: :exception,  to: :paid
  end

  event :cancel_payment do
    transition from: :paid, to: :pending
    transition from: :staggered, to: :pending
  end

  event :confirm do
    transition from: :paid,       to: :confirmed
    transition from: :scheduled,  to: :confirmed
    transition from: :exception,  to: :confirmed
  end

  event :schedule do
    transition from: :paid,       to: :scheduled
    transition from: :scheduled,  to: :scheduled
    transition from: :confirmed,  to: :scheduled
    transition from: :en_route,   to: :scheduled
    transition from: :delivered,  to: :scheduled
    transition from: :exception,  to: :scheduled
  end

  event :cancel do
    transition from: :back_order,        to: :canceled
    transition from: :pre_sale,          to: :canceled
    transition from: :paid,              to: :canceled
    transition from: :scheduled,         to: :canceled
    transition from: :confirmed,         to: :canceled
    transition from: :en_route,          to: :canceled
    transition from: :exception,         to: :canceled
    transition from: :delivered,         to: :canceled
  end

  event :accept do
    transition from: :confirmed,        to: :accepted
    transition from: :exception,        to: :accepted
    transition from: :en_route,         to: :accepted
  end

  event :start_delivery do
    transition from: :confirmed,        to: :en_route
    transition from: :exception,        to: :en_route
    transition from: :accepted,         to: :en_route
  end

  event :deliver do
    transition from: :confirmed,  to: :delivered
    transition from: :exception,  to: :delivered
    transition from: :en_route,   to: :delivered
  end

  event :exception do
    transition from: :back_order,       to: :exception
    transition from: :pre_sale,         to: :exception
    transition from: :paid,             to: :exception
    transition from: :scheduled,        to: :exception
    transition from: :confirmed,        to: :exception
    transition from: :en_route,         to: :exception
    transition from: :delivered,        to: :exception
    transition from: :accepted,         to: :exception
  end

  event :test do
    transition from: :canceled, to: :test
  end

  after_transition do |shipment, transition|
    new_state = ->(to_state) { to_state == 'paid' ? 'ready_to_ship' : to_state }

    shipment.update! state: new_state.call(transition.to_state)

    shipment.broadcast_event(:shipment_state_changed)
  end

  # TODO: Do we need to guard any of these transitions?
  # TODO: Do we need to adjust any callbacks in the event of transitioning from
  #       the exception state back to a normal state?

  guard_transition(to: :scheduled) do |shipment|
    # We don't want to schedule orders in the past. We are adding 2 hours in order to account for the 2-hour
    # scheduling window size, possibly want to review if we introduce dynamic window sizes.
    #
    # TODO: JM: Now we have flexible scheduling windows, we should save the Biz::Period (shipping_window).
    in_supplier_zone = ->(zone, time) { time.in_time_zone(zone) }.curry[shipment.supplier_timezone]
    scheduled_after  = ->(time, **advance) { time.is_a?(Time) && in_supplier_zone[time].advance(advance).future? }

    shipment.exception? || scheduled_after.call(shipment.scheduled_for, hours: 2)
  end

  before_transition(to: :paid, from: :pending) do |shipment, _transition|
    shipment.save_shipment_amount

    # TODO: This should be moved until after the transition, else it defaults to updated_at and
    #       may not trigger correctly.
    shipment.set_out_of_hours
  end

  after_transition(to: :paid, from: :pending, after_commit: true) do |shipment, _transition|
    shipment.broadcast_event(:shipment_paid)
    shipment.set_asana_scheduled_reminders('paid') if shipment.scheduled_for.present?
    shipment.set_no_tracking_number_reminders if shipment.shipping_method.shipped?
  end

  before_transition(to: :confirmed) do |shipment, _transition|
    shipment.confirmed_at = Time.current
  end

  after_transition(to: :confirmed, after_commit: true) do |shipment, _transition|
    shipment.broadcast_event(:shipment_confirmed)
  end

  after_transition(to: :en_route) do |shipment, transition|
    # do nothing
  end

  before_transition(to: :canceled) do |shipment, _transition|
    shipment.canceled_at = Time.current
  end

  after_transition(to: :canceled, from: :pre_sale, after_commit: true) do |shipment, _transition|
    PreSales::DecreaseOrderQtyWorker.perform_in(5.seconds, shipment.id)
  end

  after_transition(to: :canceled, after_commit: true) do |shipment, _transition|
    shipment.refund! if shipment.customer_placement_standard? || !%w[pre_sale back_order].include?(shipment.previous_state)
    shipment.broadcast_event(:shipment_canceled)
  end

  after_transition(to: :scheduled, after_commit: true) do |shipment, _transition|
    # [TECH-2575] DSP will only be scheduled when confirmed
    # RequestDeliveryServiceWorker.perform_async(shipment.id) if order_delivery?(shipment)
    shipment.set_scheduled_reminders
  end

  before_transition(to: :delivered) do |shipment, _transition|
    shipment.delivered_at = Time.current
  end

  after_transition(to: %i[en_route delivered], after_commit: true) do |shipment, _|
    order = shipment.order
    fulfillment_status = order.fulfillment_status
    order.bar_os_order_send!(fulfillment_status) if fulfillment_status
  end

  after_transition(to: :delivered, after_commit: true) do |shipment, _transition|
    shipment.broadcast_event(:shipment_delivered)
    shipment.broadcast_event(:shipment_gift_delivered) if shipment.gift?
  end

  after_transition(to: :exception, after_commit: true) do |shipment, transition|
    case transition.metadata['type']
    when 'failed_delivery'
      InternalAsanaNotificationWorker.perform_async(
        name: "FAILED DELIVERY ATTEMPT: Order #{shipment.order_number} - #{shipment.user_name}",
        notes: "Supplier #{shipment.supplier_name} reported a delivery problem with a shipment in this order.\n\n" \
                "Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_number}/edit",
        tags: [AsanaService::COMMENT_TAG_ID]
      )
    when 'payment_error'
      InternalAsanaNotificationWorker.perform_async(
        name: "FAILED PAYMENT ATTEMPT: Order #{shipment.order_number} - #{shipment.user_name}",
        notes: "Supplier #{shipment.supplier_name} reported a delivery problem with a shipment in this order.\n\n" \
                "Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_number}/edit",
        tags: [AsanaService::COMMENT_TAG_ID]
      )
    end
  end

  after_transition(from: :pending, to: :pre_sale, after_commit: true) do |shipment, _transition|
    if Feature[:pre_sale_increase_order_quantity_inline].enabled?
      PreSales::IncreaseOrderQuantity.new(shipment).call
    else
      MetricsClient::Metric.emit('minibar_web.pre_sale.transition', 1)
      PreSales::IncreaseOrderQtyWorker.perform_in(5.seconds, shipment.id)
    end
    shipment.broadcast_event(:shipment_delayed_payment)
  end

  after_transition(to: :back_order, after_commit: true) do |shipment, _transition|
    shipment.broadcast_event(:shipment_delayed_payment)
  end

  def self.order_delivery?(shipment)
    shipment.delivery_service &&
      (shipment.delivery_service.name == 'DoorDash' ||
        shipment.delivery_service.name == 'Uber') &&
      shipment.delivery_service_order.nil?
  end

  private_class_method :order_delivery?
end
