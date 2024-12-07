class Order::OrderStateMachine
  include Statesman::Machine
  include Statesman::Events

  ORDER_UPDATE_STATES = %w[paid confirmed scheduled delivered canceled].freeze

  state :in_progress, initial: true
  state :finalizing
  state :placed
  state :verifying
  state :paid
  state :confirmed
  state :scheduled
  state :delivered
  state :canceled

  event :finalize do
    transition from: :in_progress, to: :finalizing
  end

  event :cancel_finalize do
    transition from: :finalizing, to: :in_progress
    transition from: :placed, to: :in_progress
  end

  event :place do
    transition from: :finalizing, to: :placed
  end

  event :verify do
    transition from: :finalizing, to: :verifying
    transition from: :placed, to: :verifying
  end

  event :pay do
    transition from: :verifying, to: :paid
  end

  event :confirm do
    transition from: :paid, to: :confirmed
    transition from: :confirmed, to: :confirmed
    transition from: :scheduled, to: :confirmed
  end

  event :deliver do
    transition from: :confirmed, to: :delivered
  end

  event :schedule do
    transition from: :paid, to: :scheduled
    transition from: :confirmed, to: :scheduled
    transition from: :scheduled, to: :scheduled
  end

  event :cancel do
    transition from: :verifying, to: :canceled
    transition from: :paid, to: :canceled
    transition from: :confirmed, to: :canceled
    transition from: :scheduled, to: :canceled
    transition from: :finalizing, to: :canceled
    transition from: :placed, to: :canceled
    transition from: :delivered, to: :canceled
  end

  before_transition to: :confirmed do |order, _transition|
    order.confirmed_at = Time.current
  end

  before_transition to: :verifying do |order, _transition|
    order.completed_at = Time.current
  end

  before_transition to: :canceled do |order, _transition|
    order.refund_order_charges!
    order.cancelled_at = Time.current
  end

  after_transition do |order, transition|
    order.update!(state: transition.to_state)
    order.user.invalidate_previous_order_items_cache! if order.processed?
  end

  after_transition after_commit: true do |order, transition|
    MetricsClient::Metric.emit("minibar_web.state_machine.order.transition.to.#{transition.to_state}", 1)
    order.broadcast_event(transition.to_state, prefix: true)

    begin
      # send webhook if order is in one of the states that we want to send a webhook for
      Webhooks::OrderUpdateWebhookWorker.perform_async(order.id) if transition.to_state.in?(ORDER_UPDATE_STATES)
    rescue StandardError => e
      Rails.logger.error("Error while checking webhook condition: #{e.message}")
    end
  end

  after_transition(to: :canceled, after_commit: true) do |order, _|
    order.bar_os_order_send!(:canceled)
    Memberships::Refund.new(membership: order.membership).call if order.membership_plan_id.present? && order.membership.present?
  end

  after_transition(to: :placed, after_commit: true) do |order, _|
    # :finalize kafka message is the name defined to create order in Shopify
    order.bar_os_order_send!(:finalize)
  end
end
