class AsanaListener < Minibar::Listener::Base
  subscribe_to Comment, Shipment, Sift::Decision

  def decision_created(decision)
    return unless decision.fraud?
    return unless decision.subject_type.in?(%w[User Order])

    if decision.subject_type == 'User'
      # if decision for order exists, return
      # if no decision for order, it MIGHT mean that
      # sift didn't did a webhook callback for order
      # so we need to proceed
      recent_orders = decision.subject.orders.where('created_at >= ?', 2.hours.ago)
      return if recent_orders.empty?

      order_decisions = Sift::Decision.where(subject_type: 'Order', subject_id: recent_orders.map(&:id))
      order_decisions = order_decisions.where('created_at >= ?', 2.hours.ago)
      return if order_decisions.count == recent_orders.count
    end

    decision.applicable_orders.each do |order|
      next if %w[in_progress canceled].include?(order.state)
      next unless order.completed_at > Time.current.beginning_of_day

      if order.verifying? || order.paid? || order.scheduled?
        InternalAsanaNotificationWorker.perform_async(
          tags: [AsanaService::FRAUD_TAG_ID],
          name: "Fraudulent Order #{order.number} - #{order.user_name}",
          notes: "Sift believes that this order may be fraudulent. \n\nOrder: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{order.id}/edit \n\nSift: https://console.siftscience.com/users/#{order.user.referral_code}/?abuse_type=payment_abuse"
        )
      elsif order.confirmed? || order.delivered?
        InternalAsanaNotificationWorker.perform_async(
          tags: [AsanaService::FRAUD_TAG_ID],
          name: "Fraudulent Account - #{order.user_name}",
          notes: "Sift believes that this customer may be fraudulent. \n\nCustomer: #{ENV['ADMIN_SERVER_URL']}/admin/customers/#{order.user_id}/edit \n\nSift: https://console.siftscience.com/users/#{order.user.referral_code}/?abuse_type=payment_abuse"
        )
      end
    end
  end

  def shipment_paid(shipment)
    if shipment.out_of_hours? && !shipment.scheduled_for?
      InternalAsanaNotificationWorker.perform_async(
        tags: [AsanaService::OUT_OF_HOURS_TAG_ID],
        name: "Order #{shipment.order_number} - #{shipment.user_name}",
        notes: "Order with #{shipment.supplier_name} placed out of hours. \n\nOrder: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_id}/edit"
      )
    end
  end

  def shipment_unconfirmed(shipment)
    return if shipment.out_of_hours? && !shipment.scheduled_for
    return if shipment.digital?
    return if %w[shipped].include?(shipment.shipping_type)

    InternalAsanaNotificationWorker.perform_async(
      tags: [AsanaService::UNCONFIRMED_TAG_ID],
      name: "Order #{shipment.order_number} - #{shipment.user_name}",
      notes: "Order with #{shipment.supplier_name} has not been confirmed.\n\n \n\nOrder: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_id}/edit"
    )
  end

  def comment_created(comment, _ = {})
    asana_notification_params = comment.asana_notification_params
    return unless asana_notification_params || (comment.commentable_type == 'Shipment' && comment.posted_by_supplier?) || (comment.commentable_type == 'Order' && comment.posted_by_delivery_service?)

    if asana_notification_params
      InternalAsanaNotificationWorker.perform_async(asana_notification_params)
    elsif comment.commentable_type == 'Shipment'
      shipment = comment.commentable

      InternalAsanaNotificationWorker.perform_async(
        tags: [AsanaService::COMMENT_TAG_ID],
        name: "Order #{shipment.order_number} - #{shipment.user_name}",
        notes: "Comment added by #{shipment.supplier_name}: \n\n #{comment.note}\n\n Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_id}/edit"
      )
    else
      order = comment.commentable

      InternalAsanaNotificationWorker.perform_async(
        tags: [AsanaService::COMMENT_TAG_ID],
        name: "Order #{order.number} - #{order.user_name}",
        notes: "Comment added by Delivery Service: \n\n #{comment.note}\n\n Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{order.id}/edit"
      )
    end
  end

  def comment_reminder(comment)
    return unless comment.commentable_type == 'Shipment'

    shipment = comment.commentable

    InternalAsanaNotificationWorker.perform_async(
      tags: [AsanaService::COMMENT_TAG_ID],
      name: "COMMENT REMINDER: #{shipment.order_number} - #{shipment.user_name}",
      notes: "Comment not acknowledged by supplier after 15 minutes.\n\n #{shipment.supplier_name}: \n\n #{comment.note}\n\n Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{shipment.order_id}/edit"
    )
  end
end
