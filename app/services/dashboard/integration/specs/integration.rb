module Dashboard
  module Integration
    module Specs
      class Integration
        API_BASE_URL = ENV['SPECS_API_URL']

        def initialize(token)
          @api = Faraday.new(
            url: "#{API_BASE_URL}/wp-json/portal",
            headers: {
              'Vendor' => 'Minibar',
              'Content-Type' => 'application/json',
              'API-Key' => token
            }
          ) do |faraday|
            faraday.response :logger
            faraday.response :json, parser_options: { object_class: OpenStruct }
            faraday.adapter Faraday.default_adapter
          end
        end

        def add_order(order)
          payload = get_order_payload(order)

          request = nil
          response = @api.post('add_order') do |req|
            req.body = payload.to_json
            request = req
          end

          [request, response]
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

        def get_order_payload(order)
          payload = {
            "order": {
              "id": order.id,
              "order_reference_number": order.order_reference_number,
              "tax_rate": order.summary.tax_rate.to_f.round_at(2),
              "tax_total": order.summary.tax_total.to_f.round_at(2),
              "total": order.summary.total.to_f.round_at(2),
              "subtotal": order.summary.subtotal.to_f.round_at(2),
              "fees_total": order.summary.fees_total.to_f.round_at(2),
              "pickup_name": 'DoorDash',
              "order_special_instructions": order.delivery.order_special_instructions || '',
              "store_number": order.store_number,
              "fulfillment_time_utc": (order.fulfillment_time || Time.zone.now).utc.strftime('%Y-%m-%d %H:%M:%S')
            },
            "customer": order.customer_details,
            "delivery_address": order.delivery.shipping_details,
            "order_lines": order.items
          }

          payload[:order][:tip] = order.tip if order.tip

          payload
        end
      end
    end
  end
end
