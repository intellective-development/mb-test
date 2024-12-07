class SubscriptionService
  attr_reader :to_notify, :to_process

  def initialize
    @to_notify = Subscription.to_notify
    @to_process = Subscription.to_process

    # Rails.logger.level = 0
    Rails.logger.info("SUBSCRIPTION_SERVICE: #{@to_notify.size} to notify. #{@to_process.size} to process.")
  end

  #-----------------------------------
  # Class methods
  #-----------------------------------

  def self.create_subscription(order, interval = 7)
    order.create_subscription(interval: interval)
  end

  def self.process_subscription(subscription)
    order = subscription.user.orders.new(network_attributes(subscription.base_order, subscription))

    cart = nil
    order_service = OrderCreationServices.new(order, subscription.user, cart, order_params(subscription), skip_in_stock_check: true)

    order_service.build_order
    raise order_service.error_args.inspect unless order_service.valid?

    order.save!
    order.finalize!

    subscription.assign_attributes(last_order: order)

    finalize = FinalizeOrderService.new(order, { skip_legal_age_agreement: true })

    if finalize.process
      Rails.logger.info("SUBSCRIPTION_SERVICE: Order #{order.id} created for #{subscription.id}.")
      subscription.set_next_order_date
      subscription.increment_order_count
      subscription.save
    else
      Rails.logger.error "SUBSCRIPTION #{subscription.id}: Failed"
      Rails.logger.error finalize.errors.full_messages.to_sentence
      raise finalize.errors.full_messages.to_sentence
    end
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def process!
    process_notifications!
    process_renewals!
  end

  def process_notifications!
    @to_notify.find_each do |subscription|
      SubscriptionNotificationMailWorker.perform_at(notification_time(subscription), subscription.id)
    end
  end

  def process_renewals!
    @to_process.find_each do |subscription|
      SubscriptionWorker.perform_at(notification_time(subscription), subscription.id)
    end
  end

  def notification_time(subscription)
    # We want to send this email at 4pm, relative to the order supplier
    Time.use_zone(supplier_timezone(subscription)) do
      Time.zone.parse('16:00', subscription.next_order_date.ago(1.day))
    end
  end

  def processing_time(subscription)
    # We want to process subscriptions at 6am each morning
    Time.use_zone(supplier_timezone(subscription)) do
      Time.zone.parse('06:00', subscription.next_order_date)
    end
  end

  private

  def self.network_attributes(base_order, subscription)
    {
      ip_address: base_order.ip_address,
      platform: 'subscription',
      client: base_order.client,
      subscription_id: subscription.id,
      storefront: base_order.storefront
    }
  end

  def self.order_params(subscription)
    params = {
      shipping_address_id: subscription.base_order.ship_address_id,
      payment_profile_id: subscription.payment_profile_id,
      tip: subscription.base_order.tip_amount.to_f,
      delivery_notes: subscription.base_order.delivery_notes,
      order_items: item_params(subscription.base_order.order_items, subscription.next_order_date)
    }
    params[:shoprunner_token] = subscription.base_order.shoprunner_token if Feature[:shoprunner_backend].enabled?(subscription.user)
    params
  end

  def self.item_params(order_items, scheduled_for)
    order_items.map do |order_item|
      {
        id: order_item.variant_id,
        variant_id: order_item.variant_id,
        identifier: order_item.variant_id,
        quantity: order_item.quantity,
        delivery_method_id: order_item.shipping_method.id,
        scheduled_for: scheduled_for
      }
    end
  end

  def supplier_timezone(subscription)
    subscription.base_order.shipments.first.supplier.timezone
  end
end
