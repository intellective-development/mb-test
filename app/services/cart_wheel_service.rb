# class DoorDashError < StandardError; end

class CartWheelService
  require 'faraday'
  attr_reader :shipment

  PICKUP_DELIVERY_TIME = 15
  DROPOFF_DELIVERY_TIME = 60
  SCHEDULED_WINDOW_DELIVERY_TIME = 60

  def initialize(shipment)
    @shipment = shipment
    @conn = Faraday.new(
      url: 'https://minibar.cartwheel.tech',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => 'Basic bWluaWJhcjpmVGRzWV9WVVU4YVA4ekJ6'
      }
    ) do |faraday|
      faraday.response :json, parser_options: { object_class: OpenStruct }
      faraday.adapter Faraday.default_adapter
    end
    @cart_wheel = RegisteredAccount.cart_wheel.user
    @notes = I18n.translate('notes')
  end

  def get_order_status(order_id)
    url = "/app-portal/dynamic/api/status/#{order_id}"

    get(url)
  end

  def create_delivery
    parsed_response = create_delivery_job
    external_order_id = parsed_response['job_id']

    if external_order_id
      shipment.external_order_id = external_order_id
      shipment.save!

      note = I18n.translate('notes.delivery_order_created', order_number: external_order_id)
    else
      note = parsed_response['message']
    end
    comment = shipment.comments.new(note: note, created_by: @cart_wheel.id)
    comment.save
  end

  private

  def get(url)
    api_response = @conn.get do |req|
      req.url(url)
    end
    api_response.body
  end

  def post(url, body)
    api_response = @conn.post do |req|
      req.url(url)
      req.body = body.to_json
    end
    api_response.body
  end

  def create_delivery_job
    url = '/app-portal/dynamic/api/jobs'

    order_id = "#{shipment.order_id}_#{shipment.id}"

    body = {
      order_id: order_id,
      order_items: order_items,
      order_total: shipment.total_amount.to_f,
      tip: shipment.shipment_amount.tip_amount.to_f,
      controlled_substances: {
        control: true
      }
    }

    body[:pickup_waypoint] = pickup_info
    body[:dropoff_waypoint] = dropoff_info
    post(url, body)
  end

  def order_items
    shipment.order_items.map do |order_item|
      volume = order_item&.variant&.product&.item_volume
      price = ActiveSupport::NumberHelper.number_to_currency(order_item.price)

      {
        name: "#{order_item.product_size_grouping.name} #{volume}",
        quantity: order_item.quantity,
        description: "#{price} (#{volume})"
      }
    end
  end

  def pickup_info
    pickup_address = shipment.supplier_address
    pickup_address.geocode! unless pickup_address.blank? && pickup_address.geocoded?

    {
      name: shipment.supplier.delivery_service_config ? shipment.supplier.delivery_service_config.name : 'Minibar Delivery',
      phone: shipment.supplier_address.phone || '',
      address: format_address(pickup_address),
      external_pickup_id: shipment.supplier.id,
      city: pickup_address&.city,
      state: pickup_address&.state&.abbreviation,
      zip: pickup_address&.zip_code,
      location: {
        latitude: pickup_address&.latitude,
        longitude: pickup_address&.longitude
      },
      arrive_at: pickup_time.strftime('%FT%T%z')
    }
  end

  def dropoff_info
    dropoff_address = shipment.address
    dropoff_address.geocode! unless dropoff_address.blank? && dropoff_address&.geocoded?

    {
      name: shipment.recipient_name,
      phone: shipment.recipient_phone,
      address: format_address(dropoff_address),
      city: dropoff_address&.city,
      state: dropoff_address&.state_name,
      zip: dropoff_address&.zip_code,
      location: {
        latitude: dropoff_address&.latitude,
        longitude: dropoff_address&.longitude
      },
      arrive_at: dropoff_time.strftime('%FT%T%z')
    }
  end

  def pickup_time
    shipment.scheduled_for.nil? ? asap_time : schedule_time
  end

  def dropoff_time
    (shipment.scheduled_for.nil? ? shipment.order.completed_at : schedule_time) + DROPOFF_DELIVERY_TIME.minutes
  end

  def asap_time
    Time.current + PICKUP_DELIVERY_TIME.minutes
  end

  def schedule_time
    shipment.scheduled_for.to_datetime + SCHEDULED_WINDOW_DELIVERY_TIME.minutes
  end

  def format_address(address)
    "#{address&.address1} #{address&.address2}"
  end
end
