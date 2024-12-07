require 'faraday'

module Dashboard
  module Integration
    module ThreeJMS
      class Integration
        def initialize(supplier)
          @api = Faraday.new(
            url: supplier.three_jms_credential.api_url,
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'Authorization' => "Token #{supplier.three_jms_credential.api_key}"
            }
          ) do |faraday|
            faraday.response :logger
            faraday.response :json, parser_options: { object_class: OpenStruct }
            faraday.adapter Faraday.default_adapter
          end
        end

        def place_order(order)
          place_order_url = '/api/v1/order/new/'

          payload = get_order_payload(order)

          if %w[pre_sale].include?(order.order_type)
            payload[:status] = 'action_req'
            payload[:substatus] = 'Backorder'
          end

          request = nil
          response = @api.post(place_order_url) do |req|
            req.body = payload.to_json
            request = req
          end

          Rails.logger.info("[3JMS Dashboard] Sending place_order. Request: #{request.inspect}. Response: #{response.inspect}")

          [request, response]
        end

        def cancel_order(external_order_id)
          cancel_order_url = '/api/v1/order/cancel/'
          payload = {
            retailer_order_id: external_order_id
          }

          request = nil
          response = @api.post(cancel_order_url) do |req|
            req.body = payload.to_json
            request = req
          end

          [request, response]
        end

        def update_order(order)
          order_id = get_3jms_order_id(order.id)
          update_order_url = "/api/v1/order/#{order_id}/"
          payload = get_order_payload(order)

          request = nil
          response = @api.patch(update_order_url, payload.to_json) do |req|
            request = req
          end

          Rails.logger.info("[3JMS Dashboard] Sending update_order. Request: #{request.inspect}. Response: #{response.inspect}")

          [request, response]
        end

        def update_order_status(order_id, status, substatus = nil)
          update_status_url = '/api/v1/order/change_status/'
          body = {
            status: status,
            retailer_order_id: order_id
          }

          body[:substatus] = substatus unless substatus.nil?

          request = nil
          response = @api.post(update_status_url) do |req|
            req.body = body.to_json
            request = req
          end

          [request, response]
        end

        def send_comment(order_id, note)
          payload = {
            "order": order_id,
            "description": note
          }.to_json

          request = nil
          response = @api.post('/api/v1/order/internal-note/') do |req|
            req.body = payload
            request = req
          end

          Rails.logger.info("[3JMS Dashboard] Sending comment. Request: #{request.inspect}. Response: #{response.inspect}")

          [request, response]
        end

        def get_3jms_order_id(external_shipment_id)
          response = get_3jms_order(external_shipment_id)

          response&.dig('id')
        end

        def get_3jms_order_status(external_shipment_id)
          response = get_3jms_order(external_shipment_id)

          response&.dig('status')
        end

        def get_3jms_order(external_shipment_id)
          response = @api.get("/api/v1/order/?search=#{external_shipment_id}")

          response.body[:results][0] if response.status == 200 && (response.body[:count].to_i || 0).positive?
        end

        private

        def get_order_items_payload(items)
          items.map do |item|
            payload = {
              "sku": item.sku,
              "name": item.name,
              "price_retail": item.price,
              "quantity": item.qty
            }

            if item.engraving.present?
              engraving_lines = []
              engraving_lines << item.engraving.line1 if item.engraving.line1.present?
              engraving_lines << item.engraving.line2 if item.engraving.line2.present?
              engraving_lines << item.engraving.line3 if item.engraving.line3.present?
              engraving_lines << item.engraving.line4 if item.engraving.line4.present?

              payload[:engraving_lines] = engraving_lines
            end

            payload
          end
        end

        def get_order_payload(order)
          ship_address = order.ship_to

          items = get_order_items_payload(order.items)

          payload = {
            "retailer_order_id": order.id,
            "customer_name": ship_address.name,
            "customer_email": order.email || 'N/A',
            "company": ship_address.company || nil,
            "telephone": order.phone || 'N/A',
            "address1": ship_address.address1,
            "address2": ship_address.address2 || nil,
            "zipcode": ship_address.zip_code,
            "city": ship_address.city,
            "state_code": ship_address.state.abbreviation,
            "country_code": 'US',
            "items": items,
            "brand": order.brand
          }

          payload['packingslip_qrcode'] = order.qr_code if order.qr_code.present?

          payload[:giftmessage_text] = order.gift_detail&.message if order.gift_detail.present? && order.gift_detail&.message.present?

          payload
        end
      end
    end
  end
end
