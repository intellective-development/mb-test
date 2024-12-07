module Dashboard
  module Integration
    module SevenEleven
      class Integration
        PARTNER_NAME = 'minibar'.freeze
        API_BASE_URL = ENV['SEVEN_ELEVEN_NOW_API_URL']

        def self.authenticate(client_id, client_secret)
          oauth_response = Faraday.post("#{API_BASE_URL}/oauth/accesstoken", { client_id: client_id, client_secret: client_secret }) do |req|
            req.params['grant_type'] = 'client_credentials'
            req.headers['Cache-Control'] = 'no-cache'
          end

          oauth_body = JSON.parse(oauth_response.body)

          return oauth_body['access_token'] if oauth_response.status == 200
        end

        def initialize(token)
          @api = Faraday.new(
            url: "#{API_BASE_URL}/now",
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{token}"
            }
          ) do |faraday|
            faraday.response :logger, nil, { headers: true, bodies: true, errors: true, log_level: :debug }
            faraday.response :json, parser_options: { object_class: OpenStruct }
            faraday.adapter Faraday.default_adapter
          end
        end

        def verify_order(order)
          payload = get_base_order_payload(order)
          payload[:action] = 'verify'

          post_order_action(payload)
        end

        def checkout_order(order)
          payload = get_base_order_payload(order)
          payload[:action] = 'checkout'

          post_order_action(payload)
        end

        def submit_order(order, order_id)
          payload = get_base_order_payload(order)
          payload[:action] = 'submit'
          payload[:data][:order_id] = order_id

          post_order_action(payload)
        end

        def cancel_order(order_id)
          payload = {
            "action": 'cancel',
            "source": PARTNER_NAME,
            "data": {
              "order_id": order_id.to_s
            }
          }

          post_order_action(payload)
        end

        def store_details(store_id)
          @api.get("store/#{store_id}")
        end

        def store_menu(store_id)
          @api.get("store/#{store_id}/menu")
        end

        private

        def post_order_action(payload)
          request = nil
          response = @api.post('order') do |req|
            req.body = payload.to_json
            request = req
          end

          [request, response]
        end

        def get_base_order_payload(order)
          payload = {
            "source": PARTNER_NAME,
            "data": {
              "store_id": order.store_id.to_s,
              "order_type": order.order_type,
              "items": order.items
            }
          }

          if order.order_type == 'delivery'
            payload[:data][:shipping] = {
              "dropoff": {
                "country": 'US',
                "city": order.shipping.city,
                "state": order.shipping.state,
                "zip": order.shipping.zip.to_s,
                "street": order.shipping.street,
                "coordinates": {
                  "latitude": order.shipping.lat,
                  "longitude": order.shipping.lng
                }
              }
            }
            payload[:data][:shipping][:delivery_notes] = order.shipping.delivery_notes unless order.shipping.delivery_notes.nil?
          end

          payload[:data][:fee_items] = order.fee_items if order.fee_items.present?

          payload[:data][:payment_details] = order.payment_details unless order&.payment_details.nil?

          payload[:data][:meta_info] = order.meta_info unless order&.meta_info.nil?

          payload[:data][:user_profile] = order.user_profile unless order&.user_profile.nil?

          payload[:data][:tip_details] = { "tip_amount": order.tip } unless order&.tip.nil?

          unless order&.commission_rate.nil? || order&.commission_amt.nil?
            payload[:data][:commission_rate] = order.commission_rate
            payload[:data][:commission_amt] = order.commission_amt
          end

          payload
        end
      end
    end
  end
end
