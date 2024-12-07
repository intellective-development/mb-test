class DeliverySolutionsError < StandardError; end
class DeliverySolutionsEstimatesError < StandardError; end
class DeliverySolutionsAssuranceError < StandardError; end
class DeliverySolutionsCancelationError < StandardError; end

class DeliverySolutionsService
  require 'faraday'
  require 'action_view'
  include ActionView::Helpers::DateHelper

  DELIVERY_ASSURANCE_URI = '/api/v2/deliveryAssurance'.freeze
  MEDIUM_PACKAGE_CAPACITY = (4..12).freeze
  SCHEDULED_WINDOW_DELIVERY_TIME = 120 # minutes within time window

  def initialize
    @conn = Faraday.new(url: ENV['DELIVERY_SOLUTIONS_URL']) do |connection|
      connection.use FaradayMiddleware::FollowRedirects

      # The adapter MUST be defined last as it relays on the previous configs.
      connection.adapter Faraday.default_adapter
    end

    @delivery_solutions = RegisteredAccount.delivery_solutions.user
    @notes = I18n.translate('notes')
  end

  def create_delivery(shipment_id)
    shipment = Shipment.find(shipment_id)

    delivery_request(shipment).tap do |response|
      shipment.tap do |shp|
        shp.external_order_id = response['orderId']
        shp.delivery_service_order = response
        shp.save
      end

      raise DeliverySolutionsError, 'Failed to create order' if response['orderId'].nil?

      if response['estimatedPickupTime']
        timezone = shipment.supplier ? ActiveSupport::TimeZone::MAPPING.key(shipment.supplier.timezone) : 'Eastern Time (US & Canada)'
        note = I18n.translate('notes.delivery_order_created_with_time', order_number: response['orderId'], delivery_time: response['estimatedPickupTime'].to_datetime.in_time_zone(timezone).strftime('%b %e @ %l:%M %P %Z'))
      else
        note = I18n.translate('notes.delivery_order_created', order_number: response['orderId'])
      end

      shipment.comments.new(note: note, created_by: @delivery_solutions.id).save
    end
  end

  def get_delivery_assurance(shipment_id)
    shipment = Shipment.find(shipment_id)
    body = delivery_assurance_body(shipment)

    response = delivery_request(shipment, DELIVERY_ASSURANCE_URI, body)

    raise DeliverySolutionsAssuranceError if invalid_delivery_assurance?(response)
  end

  def create_estimate(shipment_id)
    shipment = Shipment.find(shipment_id)

    response = delivery_request(shipment, '/api/v2/order/estimates')
    raise DeliverySolutionsEstimatesError if invalid_estimates?(response)
  end

  def delivery_request(shipment, url = '/api/v2/order/placeorder', body = nil)
    body ||= delivery_create_content(shipment)

    api_response = post(url, body, shipment.order)
    JSON.parse(api_response.body)
  end

  def cancel_order(order_id)
    order = Order.find(order_id)
    order.shipments.each do |shipment|
      next unless shipment.delivery_service&.name == 'DeliverySolutions'

      delivery_order_id = shipment.delivery_service_order['orderId']
      do_cancel(delivery_order_id, shipment)
    end
  end

  def cancel_shipment(shipment_id)
    shipment = Shipment.find(shipment_id)
    delivery_order_id = shipment.delivery_service_order['id']
    do_cancel(delivery_order_id, shipment)
  end

  def reschedule_order(order_id)
    order = Order.find(order_id)
    order.shipment_ids.each { |shipment_id| reschedule_shipment(shipment_id) }
  end

  def reschedule_shipment(shipment_id)
    shipment = Shipment.find shipment_id
    return unless shipment.delivery_service&.name == 'DeliverySolutions'

    delivery_order_id = shipment.delivery_service_order['orderId']
    do_cancel(delivery_order_id, shipment)
    create_delivery(shipment.id)
  end

  def create_stores
    stores_details.each do |store|
      @conn.post do |req|
        req.url('/api/v2/store')
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-API-KEY'] = ENV['DELIVERY_SOLUTIONS_KEY']
        req.body = store.to_json
      end
    end
  end

  private

  def invalid_estimates?(response)
    response['estimates'].blank? &&
      response['orderId'].blank?
  end

  def invalid_delivery_assurance?(response)
    response.dig('dsp', 'value').blank?
  end

  def do_cancel(delivery_order_id, commentable)
    url = "/api/v2/order/#{delivery_order_id}"
    api_response = delete(url, commentable)

    JSON.parse(api_response.body)
  end

  def post(url, body, commentable)
    @conn.post do |req|
      req.url(url)
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-API-KEY'] = ENV['DELIVERY_SOLUTIONS_KEY']
      req.headers['tenantId'] = tenant_id
      req.body = body.to_json
    rescue StandardError
      note = @notes[:delivery_service_unavailable]
      comment = commentable.comments.new(note: note, created_by: @delivery_solutions.id)
      comment.save
      raise
    end
  end

  def delete(url, commentable)
    response = @conn.delete do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-API-KEY'] = ENV['DELIVERY_SOLUTIONS_KEY']
    end

    raise DeliverySolutionsCancelationError if response.status != 200

    response
  rescue StandardError
    note = @notes[:delivery_service_unavailable]
    comment = commentable.comments.new(note: note, created_by: @delivery_solutions.id)
    comment.save
    raise
  end

  def stores_details
    Supplier.where('name iLike ?', '%total wine%').map do |supplier|
      address = supplier.address
      {
        name: supplier.name,
        storeExternalId: (supplier.external_supplier_id || supplier.id).to_s,
        description: "#{supplier.name} @ #{address.address1}",
        timeZone: supplier.timezone,
        contact: {
          name: supplier.employees.first&.name,
          phone: supplier.employees.first&.phone || address.phone
        },
        deliveryInstructions: '',
        address: {
          street: address.address1,
          street2: address.address2,
          secondary: '',
          city: address.city,
          state: address.state_name,
          zipcode: address.zip_code
        },
        departments: supplier.categories.keys.map { |x| { name: x, description: '', deliveryInstructions: '' } },
        DSPs: ['FedEx', 'Uber', 'Lash', 'Dropoff', 'DoorDash', 'Point Pickup'].map { |x| { name: x } }
      }
    end
  end

  def delivery_assurance_body(shipment)
    address = shipment.address
    supplier = shipment.supplier

    local_scheduled_time = shipment.scheduled_for.to_datetime.in_time_zone(supplier.timezone)

    pickup_time = shipment.scheduled_for.past? ? ((Time.zone.now + 15.minutes).to_datetime.in_time_zone(supplier.timezone).to_f * 1000).floor : (local_scheduled_time.to_f * 1000).floor
    dropoff_time = [
      ((local_scheduled_time + SCHEDULED_WINDOW_DELIVERY_TIME.minutes).to_f * 1000).floor,
      pickup_time + (30.minutes * 1000)
    ].max

    {
      storeExternalId: (supplier.external_supplier_id || supplier.id).to_s,
      deliveryAddress: {
        apartment: address.address2.blank? ? '' : 'yes',
        apartmentNumber: address.address2 || '',
        city: address.city,
        secondary: '',
        state: address.state_name,
        street2: '',
        street: address.address1 || '',
        zipcode: address.zip_code
      },
      pickupTime: {
        startsAt: pickup_time
      },
      dropoffTime: {
        endsAt: dropoff_time
      },
      services: ['dsp']
    }
  end

  def delivery_create_content(shipment)
    address = shipment.address
    supplier = shipment.supplier
    # supplier_name = supplier.name || shipment.supplier_address.name || ''

    local_scheduled_time = shipment.scheduled_for.to_datetime.in_time_zone(supplier.timezone)

    pickup_time = shipment.scheduled_for.past? ? ((Time.zone.now + 15.minutes).to_datetime.in_time_zone(supplier.timezone).to_f * 1000).floor : (local_scheduled_time.to_f * 1000).floor
    dropoff_time = [
      ((local_scheduled_time + SCHEDULED_WINDOW_DELIVERY_TIME.minutes).to_f * 1000).floor,
      pickup_time + (30.minutes * 1000)
    ].max

    recipient_note = I18n.translate('notes.delivery_order.gift_note', recipient_name: shipment.recipient_name, gift_recipient: shipment.gift_recipient) if shipment.gift_recipient.present?
    recipient_note = I18n.translate('notes.delivery_order.recipient_note', recipient_name: shipment.recipient_name) if shipment.gift_recipient.blank?

    {
      userEmail: shipment.recipient_email,
      storeExternalId: (supplier.external_supplier_id || supplier.id).to_s,
      orderExternalId: shipment.id.to_s,
      tips: shipment.shipment_tip_amount.to_f,
      department: 'Minibar',
      orderValue: shipment.total.to_f,
      userPickupTime: pickup_time,
      dropOffTime: dropoff_time,
      deliveryContact: {
        name: "#{shipment.user.first_name} #{shipment.user.last_name}",
        phone: address.normalized_phone
      },
      deliveryAddress: {
        apartment: address.address2.blank? ? '' : 'yes',
        apartmentNumber: address.address2 || '',
        city: address.city,
        secondary: '',
        state: address.state_name,
        street2: '',
        street: address.address1 || '',
        zipcode: address.zip_code
      },
      packages: packages(shipment.order_items),
      isSpirit: false, # We are only doing wine and beer for now.
      isBeerOrWine: true,
      isFragile: true,
      hasRefrigeratedItems: false,
      hasPerishableItems: false,
      deliveryInstructions: [shipment.order.delivery_notes, recipient_note].compact.join('; '),
      notifications: {
        email: ['help@minibardelivery.com'],
        url: "#{ENV['API_URL']}/webhooks/delivery_solutions/"
      }
    }
  end

  def packages(items)
    quantities = items.each_with_object(Hash.new(0)) do |item, count|
      category = %w[mixers wine].include?(item.hierarchy_category&.name) ? :stackable : :other

      count[category] += item.quantity
    end

    packages_count = {
      medium: quantities[:stackable].div(MEDIUM_PACKAGE_CAPACITY.max),
      small: quantities[:other]
    }

    remaining_wine_bottles_count = quantities[:stackable] % MEDIUM_PACKAGE_CAPACITY.max

    if MEDIUM_PACKAGE_CAPACITY.include?(remaining_wine_bottles_count)
      packages_count[:medium] += 1
    elsif remaining_wine_bottles_count.positive?
      packages_count[:small] += 1
    end

    [].tap do |packages|
      unless packages_count[:medium].zero?
        packages << {
          name: 'custom',
          quantity: packages_count[:medium],
          size: 'medium'
        }
      end

      unless packages_count[:small].zero?
        packages << {
          name: 'custom',
          quantity: packages_count[:small],
          size: 'small'
        }
      end
    end
  end

  def tenant_id
    ENV['DELIVERY_SOLUTIONS_URL']&.include?('sandbox') ? 'Minibar_Delivery' : 'TotalWine'
  end
end
