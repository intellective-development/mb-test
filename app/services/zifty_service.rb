class ZiftyError < StandardError; end

class ZiftyService
  require 'faraday'
  require 'action_view'
  include ActionView::Helpers::DateHelper

  def initialize
    @conn = Faraday.new(url: ENV['ZIFTY_URL'])
    @zifty = RegisteredAccount.zifty.user
    @notes = I18n.translate('notes')
  end

  def create_delivery(shipment_id)
    # POST /delivery
    shipment = Shipment.find(shipment_id)

    response = create_delivery_request(shipment)

    if response['isAvailable'].to_s == 'true'
      response['duration_in_words'] = distance_of_time_in_words(response['estimatedDropoffTime'].to_datetime, response['estimatedPickupTime'].to_datetime) unless response['estimatedDropoffTime'].nil? || response['estimatedPickupTime'].nil?
      response['id'] = response['confirmationId']
      response['delivery_id'] = shipment.id.to_s
      shipment.delivery_service_order = response
      shipment.save!
      timezone = shipment.supplier ? ActiveSupport::TimeZone::MAPPING.key(shipment.supplier.timezone) : 'Eastern Time (US & Canada)'
      note = I18n.translate('notes.delivery_order_created_with_time', order_number: response['id'], delivery_time: response['estimatedPickupTime']&.to_datetime&.in_time_zone(timezone)&.strftime('%b %e @ %l:%M %P %Z'))
    else
      note = "Failed to create Zifty delivery: #{response['unavailableReason']}"
    end

    shipment.comments.create(note: note, created_by: @zifty.id)
  end

  def create_estimate(shipment_id)
    shipment = Shipment.find(shipment_id)

    url = "/zifty/api/#{ENV['ZIFTY_ENVIRONMENT']}/#{ENV['ZIFTY_ORG_ID']}/quotes"
    body = delivery_estimate_content(shipment)

    api_response = post(url, body, shipment.order)
    body = JSON.parse(api_response.body)
    raise(ZiftyError, body) unless body['isAvailable'].to_s == 'true'

    body
  end

  def cancel_order(order_id)
    order = Order.find(order_id)
    order.shipments.each do |shipment|
      next unless shipment.delivery_service&.name == 'Zifty'

      cancel_shipment(shipment.id)
    end
  end

  def cancel_shipment(shipment_id)
    shipment = Shipment.find(shipment_id)

    delivery_order_id = shipment.delivery_service_order.try(:[], 'delivery_id')
    return unless delivery_order_id.present?

    order = shipment.order
    response = do_cancel(delivery_order_id, order)

    note = response['success'].present? ? @notes[:order_canceled_successfully] : @notes[:order_canceling_error]
    shipment.comments.create(note: note, created_by: @zifty.id)
  end

  def reschedule_order(order_id)
    order = Order.find(order_id)
    order.shipment_ids.each { |shipment_id| reschedule_shipment(shipment_id) }
  end

  def reschedule_shipment(shipment_id)
    shipment = Shipment.find shipment_id
    return unless shipment.delivery_service&.name == 'Zifty'

    delivery_order_id = shipment.delivery_service_order['delivery_id']
    cancel_api_response = do_cancel(delivery_order_id, shipment)

    if cancel_api_response['success'].present?
      response = create_delivery_request(shipment)
      if response['isAvailable'].to_s == 'true'
        response['duration_in_words'] = distance_of_time_in_words(response['estimatedDropoffTime'].to_datetime, response['estimatedPickupTime'].to_datetime) unless response['estimatedDropoffTime'].nil? || response['estimatedPickupTime'].nil?
        response['id'] = response['confirmationId']
        response['delivery_id'] = shipment.id.to_s
        shipment.delivery_service_order = response
        shipment.save!
        note = @notes[:order_rescheduled] + " (delivery service id: #{response['id']})"
      else
        note = @notes[:reschedule_order_error]
      end
      shipment.comments.create(note: note, created_by: @zifty.id)
    else
      shipment.comments.create(note: @notes[:reschedule_order_error], created_by: @zifty.id)
    end
  end

  def do_cancel(delivery_id, commentable)
    url = "/zifty/api/#{ENV['ZIFTY_ENVIRONMENT']}/#{ENV['ZIFTY_ORG_ID']}/deliveries/#{delivery_id}/cancel"
    api_response = post(url, {}, commentable)

    JSON.parse(api_response.body)
  end

  def create_delivery_request(shipment)
    url = "/zifty/api/#{ENV['ZIFTY_ENVIRONMENT']}/#{ENV['ZIFTY_ORG_ID']}/delivery"
    body = delivery_create_content(shipment)

    api_response = post(url, body, shipment.order)
    JSON.parse(api_response.body)
  end

  def post(url, body, commentable)
    @conn.post do |req|
      req.url(url)
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{ENV['ZIFTY_API_KEY']}"
      req.body = body.to_json
    rescue StandardError
      note = @notes[:delivery_service_unavailable]
      comment = commentable.comments.new(note: note, created_by: @zifty.id)
      comment.save
      raise
    end
  end

  def delivery_create_content(shipment)
    arrival_time = shipment.scheduled_for.blank? || shipment.scheduled_for.past? ? (Time.current + 5.minutes) : shipment.scheduled_for
    data = {
      pickup: pickup_info(shipment),
      dropoff: dropoff_info(shipment),
      deliveryId: shipment.id.to_s,
      orderDetails: shipment_details(shipment),
      dropoffTime: arrival_time.utc.iso8601(3),
      orderValue: shipment.total_amount.to_f,
      brandName: shipment.supplier.name
    }
    data[:tip] = shipment.shipment_amount.tip_amount.to_f if shipment.shipment_amount.present?
    data
  end

  def delivery_estimate_content(shipment)
    arrival_time = shipment.scheduled_for.blank? || shipment.scheduled_for.past? ? (Time.current + 5.minutes) : shipment.scheduled_for
    data = {
      pickup: pickup_info(shipment),
      dropoff: dropoff_info(shipment),
      dropoffTime: arrival_time.utc.iso8601(3),
      orderValue: shipment.total_amount.to_f,
      brandName: shipment.supplier.name
    }
    data[:tip] = shipment.shipment_amount.tip_amount.to_f if shipment.shipment_amount.present?
    data
  end

  def shipment_details(shipment)
    shipment.order_items.map { |oi| { title: oi.product.name, quantity: oi.quantity } }
  end

  def pickup_info(shipment)
    {
      name: shipment.supplier.name || shipment.supplier_address.name,
      instructions: shipment.supplier.config.dig('deliveryService', 'pickupInstructions')
    }.merge(address_information(shipment.supplier_address))
  end

  def dropoff_info(shipment)
    recipient_note = I18n.translate('notes.delivery_order.gift_note', recipient_name: shipment.recipient_name, gift_recipient: shipment.gift_recipient) if shipment.gift_recipient.present?
    recipient_note = I18n.translate('notes.delivery_order.recipient_note', recipient_name: shipment.recipient_name) if shipment.gift_recipient.blank?
    {
      name: shipment.recipient_name,
      instructions: [shipment.order.delivery_notes, recipient_note].join('; ')
    }.merge(address_information(shipment.address))
  end

  def address_information(address)
    {
      phoneNumber: address.phone,
      street: address.address1,
      city: address.city,
      state: address.state_name,
      postalCode: address.zip_code,
      latitude: address.latitude,
      longitude: address.longitude,
      unit: address.address2
    }
  end
end
