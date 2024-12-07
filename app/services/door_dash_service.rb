class DoorDashError < StandardError; end

class DoorDashService
  require 'faraday'
  require 'action_view'
  include ActionView::Helpers::DateHelper

  ASAP_DELIVERY_TIME = 15 # minutes after order max
  SCHEDULED_PICKUP_TIME = 15 # minutes before the order
  SCHEDULED_WINDOW_DELIVERY_TIME = 30 # minutes within time window

  def initialize
    @conn = Faraday.new(url: ENV['DOOR_DASH_URL'])
    @door_dash = RegisteredAccount.door_dash.user
    @notes = I18n.translate('notes')
  end

  def create_delivery(shipment_id, arrival_time = nil)
    shipment = Shipment.find(shipment_id)

    initialize_arrival_time(shipment, arrival_time)
    response = create_delivery_request(shipment)

    if response['field_errors'].nil?
      response['duration_in_words'] = distance_of_time_in_words(response['quoted_pickup_time'].to_datetime, response['quoted_delivery_time'].to_datetime) unless response['quoted_pickup_time'].nil? || response['quoted_delivery_time'].nil?
      response['id'] = response['delivery_id'] if response['id'].nil? && response['delivery_id'].present?
      shipment.delivery_service_order = response
      shipment.save!
      timezone = shipment.supplier ? ActiveSupport::TimeZone::MAPPING.key(shipment.supplier.timezone) : 'Eastern Time (US & Canada)'
      note = I18n.translate('notes.delivery_order_created_with_time', order_number: response['id'], delivery_time: response['quoted_delivery_time']&.to_datetime&.in_time_zone(timezone)&.strftime('%b %e @ %l:%M %P %Z'))
    else
      note = response['field_errors'].map do |e|
        reschedule_if_unavailable(shipment, @arrival_time) if e['error'] == 'DoorDash is not open for delivery at the requested pickup_time'
        e['error']
      end.join('; ')
    end

    shipment.comments.create(note: note, created_by: @door_dash.id)
  end

  def reschedule_if_unavailable(shipment, arrival_time)
    return unless !shipment.delivery_service_order && shipment.scheduled_for

    window_size = shipment.shipping_method.scheduled_interval_size.minutes
    postponed_arrival_time = arrival_time + 15.minutes
    max_arrival_time = shipment.scheduled_for + window_size
    RequestDeliveryServiceWorker.perform_in(5.minutes, shipment.id, postponed_arrival_time) if postponed_arrival_time <= max_arrival_time
  end

  def create_estimate(shipment_id)
    shipment = Shipment.find(shipment_id)

    url = '/drive/v1/estimates'
    body = delivery_create_content(shipment)

    api_response = post(get_token(shipment), url, body, shipment.order)
    body = JSON.parse(api_response.body)
    raise(DoorDashError, body) unless body['field_errors'].nil?

    body
  end

  def create_delivery_request(shipment)
    url = '/drive/v1/deliveries'
    body = delivery_create_content(shipment)

    api_response = post(get_token(shipment), url, body, shipment.order)
    JSON.parse(api_response.body)
  end

  def cancel_order(order_id)
    order = Order.find(order_id)
    order.shipments.each do |shipment|
      next unless shipment.delivery_service&.name == 'DoorDash'

      do_cancel_shipment(shipment)
    end
  end

  def cancel_shipment(shipment_id)
    shipment = Shipment.find(shipment_id)
    do_cancel_shipment(shipment)
  end

  def reschedule_order(order_id)
    order = Order.find(order_id)
    order.shipment_ids.each { |shipment_id| reschedule_shipment(shipment_id) }
  end

  def reschedule_shipment(shipment_id)
    shipment = Shipment.find shipment_id
    return unless shipment.delivery_service&.name == 'DoorDash'

    return if shipment.delivery_service_order.nil? # if order is not created yet, do nothing

    delivery_order_id = shipment.delivery_service_order['id']

    cancel_api_response = nil
    begin
      cancel_api_response = do_cancel(get_token(shipment), delivery_order_id, shipment)
    rescue StandardError
      # Ignored
    end

    if cancel_api_response&.dig('field_errors').nil?
      response = create_delivery_request(shipment)
      if response['field_errors'].nil?
        response['duration_in_words'] = distance_of_time_in_words(response['quoted_pickup_time'].to_datetime, response['quoted_delivery_time'].to_datetime) unless response['quoted_pickup_time'].nil? || response['quoted_delivery_time'].nil?
        response['id'] = response['delivery_id'] if response['id'].nil? && response['delivery_id'].present?
        shipment.delivery_service_order = response
        shipment.save!
        note = @notes[:order_rescheduled] + " (delivery service id: #{response['id']})"
      else
        note = @notes[:reschedule_order_error]
      end
      shipment.comments.create(note: note, created_by: @door_dash.id)
    else
      shipment.comments.create(note: @notes[:reschedule_order_error], created_by: @door_dash.id)
    end
  end

  private

  def get_token(shipment)
    shipment_dashboard = shipment&.supplier&.dashboard_type
    if shipment_dashboard == Supplier::DashboardType::SPECS
      ENV['SPECS_DOOR_DASH_KEY']
    else
      ENV['DOOR_DASH_KEY']
    end
  end

  # postponed_arrival_time will be nil in most of the cases,
  # introduced in [TECH-2301] changes to re-request dasher
  def initialize_arrival_time(shipment, postponed_arrival_time = nil)
    @arrival_time = postponed_arrival_time
    @arrival_time ||= shipment.scheduled_for.nil? ? (Time.current + ASAP_DELIVERY_TIME.minutes) : (shipment.scheduled_for.to_datetime + SCHEDULED_WINDOW_DELIVERY_TIME.minutes)
  end

  def do_cancel(token, delivery_order_id, commentable)
    url = "/drive/v1/deliveries/#{delivery_order_id}/cancel"
    api_response = put(token, url, commentable)

    return nil if api_response.status == 404

    JSON.parse(api_response.body)
  end

  def do_cancel_shipment(shipment)
    return if shipment.delivery_service_order.nil?

    delivery_order_id = shipment.delivery_service_order['id']
    response = do_cancel(get_token(shipment), delivery_order_id, shipment)
    success_response = response.present? && response['field_errors'].nil?

    note = success_response ? @notes[:order_canceled_successfully] : @notes[:order_canceling_error]
    shipment.comments.create(note: note, created_by: @door_dash.id)
  end

  def post(token, url, body, commentable)
    @conn.post do |req|
      req.url(url)
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{token}"
      req.body = body.to_json
    rescue StandardError
      note = @notes[:delivery_service_unavailable]
      comment = commentable.comments.new(note: note, created_by: @door_dash.id)
      comment.save
      raise
    end
  end

  def put(token, url, commentable)
    @conn.put do |req|
      req.url(url)
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{token}"
    rescue StandardError
      note = @notes[:delivery_service_unavailable]
      comment = commentable.comments.new(note: note, created_by: @door_dash.id)
      comment.save
      raise
    end
  end

  def delivery_create_content(shipment)
    body = pickup_info(shipment)
    body = body.merge(order_items_info(shipment)) if shipment.supplier_address.state_name == 'NJ'
    body.merge(dropoff_info(shipment))
  end

  # def create_webhook_url(shipment)
  #   "#{ENV['DOOR_DASH_WEBHOOKS_URL']}/?key=#{shipment.order.number}"
  # end

  def pickup_info(shipment)
    pickup_info = {
      pickup_address: format_address(shipment.supplier_address),
      pickup_instructions: shipment.supplier.config.dig('deliveryService', 'pickupInstructions'),
      pickup_phone_number: shipment.supplier_address.phone || '',
      order_value: (shipment.total_amount * 100).to_i,
      pickup_business_name: shipment.supplier.name || shipment.supplier_address.name || '',
      storefront_name: shipment.order.storefront.name,
      external_business_name: shipment.supplier.delivery_service_customer,
      external_store_id: shipment.supplier.id.to_s,
      external_delivery_id: shipment.id.to_s,
      driver_reference_tag: shipment.order.number,
      contains_alcohol: shipment.contains_alcohol?
    }
    pickup_info[:tip] = (shipment.shipment_amount.tip_amount * 100).to_i if shipment.shipment_amount.present?
    pickup_info
  end

  def dropoff_info(shipment)
    initialize_arrival_time(shipment) unless @arrival_time
    recipient_note = I18n.translate('notes.delivery_order.gift_note', recipient_name: shipment.recipient_name, gift_recipient: shipment.gift_recipient) if shipment.gift_recipient.present?
    recipient_note = I18n.translate('notes.delivery_order.recipient_note', recipient_name: shipment.recipient_name) if shipment.gift_recipient.blank?
    first_name = shipment.gift_recipient.present? ? shipment.recipient_name : shipment.user.first_name
    last_name =  shipment.gift_recipient.present? ? '' : shipment.user.last_name

    first_name.gsub!(/[^A-Za-z] /, '')
    last_name.gsub!(/[^A-Za-z] /, '')

    {
      dropoff_address: format_address(shipment.address),
      dropoff_instructions: [shipment.order.delivery_notes, recipient_note].join('; '),
      customer: {
        first_name: first_name,
        last_name: last_name,
        business_name: '',
        email: shipment.recipient_email,
        phone_number: shipment.recipient_phone
      },
      delivery_time: @arrival_time.utc.iso8601,
      signature_required: true
    }
  end

  def order_items_info(shipment)
    items = shipment.order_items.map do |order_item|
      volume = order_item.variant.product.volume_value
      product_grouping = order_item.product_size_grouping
      price_in_cents = (order_item.price * 100).to_i

      {
        name: product_grouping.name,
        description: product_grouping.description,
        quantity: order_item.quantity,
        external_id: product_grouping.id.to_s,
        volume: volume,
        price: price_in_cents
      }
    end

    { items: items }
  end

  def format_address(address)
    {
      street: address.address1,
      unit: address.address2,
      city: address.city,
      state: address.state_name,
      zip_code: address.zip_code,
      full_address: address.full_street_address
    }
  end
end
