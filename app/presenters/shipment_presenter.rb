class ShipmentPresenter < BasePresenter
  delegate :description, to: :delivery_estimate, prefix: true, allow_nil: true
  delegate :display_time, :link_to, to: :view

  def display_status
    if confirmed? || delivered? || en_route? && confirmed_at
      status = "Confirmed at #{display_time(confirmed_at, supplier)} - #{delivery_estimate_description}. "
      status << "Marked as delivered at #{display_time(delivered_at, supplier)}." if delivered? && delivered_at
      status
    elsif scheduled?
      "Scheduled for delivery #{display_time(scheduled_for, supplier)}."
    elsif canceled? && canceled_at
      status = " at #{display_time(canceled_at, supplier)}."
      status << ' A refund has been automatically issued for the full amount.' if refunded?
      status
    end
  end

  def display_actions
    link_to 'Cancel Shipment', view.cancel_dialogue_admin_fulfillment_order_path(order, shipment_id: id), class: 'button-cancellation' if paid? || pending? || confirmed? || scheduled? || en_route? || back_order? || pre_sale?
  end

  def display_state
    case state
    when 'ready_to_ship', 'paid'
      'Order Placed'
    when 'confirmed'
      'Confirmed'
    when 'canceled'
      'Canceled'
    when 'scheduled'
      'Scheduled'
    when 'en_route'
      'En Route'
    else
      state
    end
  end
end
