# frozen_string_literal: true

require 'faraday'

SHIP_STATION_API_URL = 'https://ssapi.shipstation.com'
SHIP_STATION_TZ = 'America/Los_Angeles'

module Dashboard
  module Integration
    module ShipStation
      # Integration is a class that implements the IntegrationInterface for ShipStation Integrations
      class Integration
        def initialize(credentials)
          raise ShipStation::Errors::InvalidCredentialError if credentials.blank?

          @api = Faraday.new(
            url: SHIP_STATION_API_URL,
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'Authorization' => "Basic #{get_token(credentials)}"
            }
          ) do |faraday|
            faraday.response :logger
            faraday.response :json, parser_options: { object_class: OpenStruct }, content_type: /\bjson$/
            faraday.adapter Faraday.default_adapter
          end
        end

        def place_order(order)
          place_order_url = 'orders/createorder'

          payload = get_order_payload(order)

          do_post(place_order_url, payload)
        end

        def cancel_order(order)
          update_order_status(order, 'cancelled')
        end

        def update_order_status(order, status)
          update_status_url = 'orders/createorder'
          payload = get_order_payload(order)
          payload[:orderStatus] = status

          do_post(update_status_url, payload)
        end

        def get_order_by_order_number(order_number, shipment_id)
          _, response = do_get("orders?orderNumber=#{order_number}")

          orders = response.body&.dig('orders')
          orders.select { |order| order['orderKey'] == "#{order_number}_#{shipment_id}" }.first if orders.present?
        end

        def get_order_status(external_shipment_id)
          response = get_order(external_shipment_id)

          response&.dig('orderStatus')
        end

        def get_order(external_shipment_id)
          _, response = do_get("orders/#{external_shipment_id}")

          response.body if response.status == 200 && response.body.present?
        end

        def get_order_fulfillments(external_shipment_id)
          _, response = do_get("fulfillments?orderId=#{external_shipment_id}")

          response.body if response.status == 200 && response.body.present?
        end

        def get_order_shipments(external_shipment_id)
          _, response = do_get("shipments?orderId=#{external_shipment_id}")

          response.body if response.status == 200 && response.body.present?
        end

        def get_webhook_resource_content(resource_url)
          _, response = do_get("#{resource_url}&pagesize=500", full_url: true)

          response.body if response.status == 200 && response.body.present?
        end

        def subscribe_to_webhooks(supplier_id)
          webhook_url = "#{ENV['API_URL']}/webhooks/ship_station/order_update/#{supplier_id}"

          _, response = do_get('webhooks')

          raise ShipStation::Errors::InvalidCredentialError if response.status == 401
          raise ShipStation::Errors::UnauthorizedError(nil, 'webhook subscription') if response.status == 403

          missing_webhook_events = []
          missing_webhook_events << 'ORDER_NOTIFY' if response.body['webhooks']&.select { |webhook| webhook['Url'] == webhook_url && webhook['HookType'] == 'ORDER_NOTIFY' }&.none?
          missing_webhook_events << 'SHIP_NOTIFY' if response.body['webhooks']&.select { |webhook| webhook['Url'] == webhook_url && webhook['HookType'] == 'SHIP_NOTIFY' }&.none?
          missing_webhook_events << 'FULFILLMENT_SHIPPED' if response.body['webhooks']&.select { |webhook| webhook['Url'] == webhook_url && webhook['HookType'] == 'FULFILLMENT_SHIPPED' }&.none?

          missing_webhook_events.each do |event|
            payload = {
              target_url: webhook_url,
              event: event,
              friendly_name: "MB/RB #{event} Webhook"
            }
            do_post('webhooks/subscribe', payload)
          end
        end

        private

        def do_post(path, body = {})
          request = nil

          response = @api.post(path) do |req|
            req.body = body.to_json
            request = req
          end

          handle_response(response)

          [request, response]
        end

        def do_get(path, full_url: false)
          request = nil

          response = @api.get(path) do |req|
            req.url path if full_url
            request = req
          end

          handle_response(response)

          [request, response]
        end

        def handle_response(response)
          raise ShipStation::Errors::RateLimitError.new(retry_in: response.headers['X-Rate-Limit-Reset'] || 60) if response.status == 429
        end

        def get_token(credentials)
          Base64.strict_encode64("#{credentials.api_key}:#{credentials.api_secret}")
        end

        def get_order_items_payload(items)
          items.map do |item|
            payload = {
              "sku": item.sku,
              "name": item.name,
              "quantity": item.qty,
              "unitPrice": item.price
            }

            if item.engraving.present?
              engraving_lines = []
              engraving_lines << { name: 'engravingLine1', value: item.engraving.line1 } if item.engraving.line1.present?
              engraving_lines << { name: 'engravingLine2', value: item.engraving.line2 } if item.engraving.line2.present?
              engraving_lines << { name: 'engravingLine3', value: item.engraving.line3 } if item.engraving.line3.present?
              engraving_lines << { name: 'engravingLine4', value: item.engraving.line4 } if item.engraving.line4.present?

              payload['options'] = engraving_lines
            end

            payload
          end
        end

        def get_order_payload(order, status: nil)
          items = get_order_items_payload(order.items)

          payload = {
            "orderKey": order.id,
            "orderNumber": order.order_number,
            "orderDate": format_datetime(order.order_date),
            "orderStatus": status || 'awaiting_shipment',
            "orderTotal": order.total_amount,
            "amountPaid": order.total_amount,
            "paymentDate": format_datetime(order.order_date),
            "taxAmount": order.tax_amount,
            "shippingAmount": order.shipping_fee,
            "shipTo": get_address_payload(order.ship_to),
            "billTo": get_address_payload(order.bill_to),
            "items": items,
            "advancedOptions": get_advanced_options_payload(order)
          }

          if order.gift_detail.present?
            payload[:gift] = true
            payload[:giftMessage] = order.gift_detail.message if order.gift_detail.message.present?
          end

          payload
        end

        def get_address_payload(address)
          payload = {
            "name": address.name,
            "company": address.company,
            "street1": address.address1,
            "street2": address.address2,
            "city": address.city,
            "state": address.state&.abbreviation,
            "postalCode": address.zip_code,
            "country": address.country
          }

          payload['phone'] = address.phone if address.phone.present?

          payload
        end

        def get_advanced_options_payload(order)
          advanced_options = {
            customField1: order.storefront_name
          }

          advanced_options[:storeId] = order.store_id if order.store_id.present?

          advanced_options
        end

        def format_datetime(date)
          date.in_time_zone(SHIP_STATION_TZ).strftime('%Y-%m-%dT%H:%M:%S')
        end
      end
    end
  end
end
