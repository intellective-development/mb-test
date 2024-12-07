# frozen_string_literal: true

class UberError < StandardError; end

# This service is used to create a delivery request with Uber
class UberDaasService
  require 'faraday'
  require 'action_view'
  include ActionView::Helpers::DateHelper

  ISO8601_UTC = '%Y-%m-%dT%H:%M:%S.%2LZ'
  NOTE_DATE_FORMAT = '%b %e @ %l:%M %P %Z'

  def initialize(shipment_id)
    @shipment = Shipment.find(shipment_id)
    @supplier = @shipment.supplier

    @conn = Faraday.new(
      url: ENV['UBER_API_URL'],
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => access_token
      }
    ) do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter :net_http
    end

    @notes = I18n.translate('notes')
  end

  def create_delivery
    response = post('deliveries', create_delivery_body)
    external_uuid = response.fetch('uuid')
    external_id = response.fetch('id')
    pickup_ready = response.fetch('pickup_ready')
    dropoff_eta = response.fetch('dropoff_eta')
    tracking_url = response.fetch('tracking_url')

    response['duration_in_words'] = distance_of_time_in_words(pickup_ready.to_datetime, dropoff_eta.to_datetime) if pickup_ready.present? && dropoff_eta.present?
    @shipment.delivery_service_order = response
    @shipment.external_order_id = external_id
    @shipment.external_shipment_id = external_uuid
    @shipment.save!
    timezone = ActiveSupport::TimeZone::MAPPING.key(@supplier.timezone)
    note = I18n.translate(
      'notes.delivery_order_created_with_time',
      order_number: external_uuid,
      delivery_time: dropoff_eta.to_datetime.in_time_zone(timezone).strftime(NOTE_DATE_FORMAT)
    )
    @shipment.comments.create!(note: note, created_by: uber_user.id)

    return unless tracking_url

    @shipment.create_tracking_detail!(reference: external_uuid, carrier: 'Uber')
    note = I18n.translate('notes.tracking', tracking_url: tracking_url)
    @shipment.comments.create!(note: note, created_by: uber_user.id)
  end

  def cancel_shipment
    response = post("deliveries/#{@shipment.external_shipment_id}/cancel", {})
    note = I18n.translate('notes.order_canceled_successfully')
    @shipment.comments.create!(note: note, created_by: uber_user.id)
    @shipment.update!(delivery_service_order: response)
  end

  private

  def access_token
    Rails.cache.fetch("uber::service::token::#{@supplier.id}", expires_in: 20.days) do
      conn = Faraday.new(url: ENV['UBER_LOGIN_URL']) do |faraday|
        faraday.request :url_encoded
        faraday.response :json
        faraday.adapter :net_http
      end

      body = {
        client_secret: @supplier.delivery_service_client_secret,
        client_id: @supplier.delivery_service_client_id,
        grant_type: 'client_credentials',
        scope: 'eats.deliveries'
      }

      api_response = conn.post do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = body
      end

      response_body = api_response.body

      raise(UberError, response_body) if response_body['error']

      "#{response_body['token_type']} #{response_body['access_token']}"
    end
  end

  def post(url, body)
    api_response = @conn.post do |req|
      req.url("v1/customers/#{@supplier.delivery_service_customer}/#{url}")
      req.body = body
    end

    response_body = api_response.body

    raise(UberError, response_body) if response_body['kind'] == 'error'

    response_body
  end

  def create_delivery_body
    body = pickup_info
    body = body.merge(robot_info) unless ENV['ENV_NAME'] == 'master'
    body.merge(dropoff_info)
  end

  def pickup_info
    arrival_time = @shipment.scheduled_for.nil? || @shipment.scheduled_for.past? ? (Time.current + 5.minutes) : @shipment.scheduled_for
    {
      pickup_address: format_address(@shipment.supplier_address),
      pickup_name: @supplier.name,
      pickup_phone_number: @shipment.supplier_address.phone || '',
      pickup_instructions: 'Pickup at the service counter',
      pickup_ready_dt: arrival_time.utc.strftime(ISO8601_UTC),
      manifest_items: manifest_items,
      manifest_reference: "Order #{@shipment.order.number}_#{@shipment.id}",
      tip: tip_amount
    }
  end

  def manifest_items
    @shipment.order_items.map do |order_item|
      {
        name: order_item.product_size_grouping.name,
        quantity: order_item.quantity,
        size: 'medium'
      }
    end
  end

  def robot_info
    {
      test_specifications: {
        robo_courier_specification: {
          mode: 'auto'
        }
      }
    }
  end

  def dropoff_info
    recipient_note = if @shipment.gift_recipient.present?
                       I18n.translate('notes.delivery_order.gift_note', recipient_name: first_name(@shipment.recipient_name), gift_recipient: first_name(@shipment.gift_recipient))
                     else
                       I18n.translate('notes.delivery_order.recipient_note', recipient_name: first_name(@shipment.recipient_name))
                     end
    {
      dropoff_name: @shipment.recipient_name,
      dropoff_address: format_address(@shipment.address),
      dropoff_phone_number: @shipment.recipient_phone,
      dropoff_notes: [@shipment.order.delivery_notes, recipient_note].join('; '),
      dropoff_verification: {
        signature_requirement: {
          enabled: true
        },
        identification: {
          min_age: 21
        }
      },
      deliverable_action: 'deliverable_action_meet_at_door',
      undeliverable_action: 'return'
    }
  end

  def first_name(full_name)
    full_name.split(' ').first
  end

  def format_address(address)
    "#{address.address1} #{address.address2}, #{address.city}, #{address.state_name}, #{address.zip_code}"
  end

  def uber_user
    @uber_user ||= RegisteredAccount.uber.user
  end

  def tip_amount
    @shipment.tip_share ? (@shipment.tip_share * 100).to_i : 0
  end
end
