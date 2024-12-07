module Dashboard
  module Integration
    module Bevmax
      class Integration
        OMNI_API_BASE_URL = ENV['BEVMAX_OMNI_API_URL']
        FEP_API_BASE_URL = ENV['BEVMAX_FEP_API_URL']
        API_KEY = ENV['BEVMAX_API_TOKEN']

        DEFAULT_HEADERS = {
          'Device-Type' => 'Web',
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'ApiKey' => API_KEY,
          'VER' => '1.0'
        }.freeze

        def initialize(_token)
          @api = Faraday.new do |faraday|
            faraday.response :logger
            faraday.response :json, parser_options: { object_class: OpenStruct }
            faraday.adapter Faraday.default_adapter
          end
        end

        def place_order(order)
          place_order_url = "#{OMNI_API_BASE_URL}/order/createOrder"
          payload = get_order_payload(order)

          request = nil
          response = @api.post(place_order_url) do |req|
            req.headers = DEFAULT_HEADERS
            req.body = payload.to_json
            request = req
          end

          [request, response]
        end

        def cancel_order(order_id)
          cancel_order_url = "#{FEP_API_BASE_URL}/order/cancelMultiOrder?reason=Customer%20Request"
          payload = [order_id]

          request = nil
          response = @api.post(cancel_order_url) do |req|
            req.headers = DEFAULT_HEADERS
            req.body = payload.to_json
            request = req
          end

          [request, parse_cancel_order_response(response, order_id)]
        end

        def update_order_status(status, order_id)
          request = nil
          response = @api.post('update_order_status') do |req|
            req.body = { status: status, order_id: order_id }.to_json
            request = req
          end

          [request, response]
        end

        private

        def get_order_items_payload(items)
          items.map do |item|
            payload = {
              "sku": item.sku,
              "quantity": item.qty,
              "price": item.price
            }
            if item.engraving
              payload[:engraving] = 1
              payload[:engravingLine1] = item.engraving.line1
              payload[:engravingLine2] = item.engraving.line2
              payload[:engravingLine3] = item.engraving.line3
            end

            payload
          end
        end

        def get_order_payload(order)
          channel_id = order.business.bevmax_channel_id
          account_id = order.business.bevmax_account_id
          partner_name = order.business.bevmax_partner_name

          raise Bevmax::Error::UnknownError "Business #{order.business.name} doesn't have the BevMax integration properly set up." if channel_id.blank? || account_id.blank? || partner_name.blank?

          ship_address = order.ship_to
          bill_address = order.bill_to
          items = get_order_items_payload(order.items)

          payload = {
            "channel": channel_id,
            "accountId": account_id,
            "orderType": 2,
            "companyName": partner_name,
            "referenceId": order.order_reference_number,
            "shipToName": ship_address.name,
            "shipToAddress": ship_address.address1,
            "shipToAddress2": ship_address.address2 || nil,
            "shipToCity": ship_address.city,
            "shipToState": ship_address.state.abbreviation,
            "shipToCountry": 'USA',
            "shipToEmail": nil,
            "shipToMobile": ship_address.phone,
            "postalCode": ship_address.zip_code,
            "billToName": bill_address.name,
            "billToAddress": bill_address.address1,
            "billToAddress2": bill_address.address2 || nil,
            "billToCity": bill_address.city,
            "billToState": bill_address.state.abbreviation,
            "billToCountry": 'USA',
            "billToEmail": nil,
            "billToMobile": nil,
            "billToPostal": bill_address.zip_code,
            "additionalCharges": nil,
            "instructions": order.delivery_notes || nil,
            "shipperId": order.store_number,
            "orderItems": items,
            "totalTax": order.total_tax,
            "shippingCost": order.shipping_cost,
            "totalDiscount": order.total_discount,
            "totalAmount": order.total_amount
          }

          unless order.gift_detail.nil?
            payload[:giftOrder] = 1
            payload[:giftNote] = order.gift_detail&.message
            payload[:giftType] = 0
          end

          payload
        end

        def parse_cancel_order_response(res, order_id)
          res if res.status >= 400

          order_res = res.body[:"#{order_id}"] || nil

          unless order_res
            return OpenStruct.new(status: 500, body: OpenStruct.new(
              'success': false,
              'message': 'Missing cancel order response',
              'originalResponse': res
            ))
          end

          OpenStruct.new(status: order_res.responseStatus, body: order_res.responseString)
        end
      end
    end
  end
end
