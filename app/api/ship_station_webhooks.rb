# frozen_string_literal: true

# ShipStationWebhooks
class ShipStationWebhooks < BaseAPI
  format :json

  namespace :order_update do
    route_param :supplier_id, type: Integer do
      desc 'Webhook endpoint for ShipStation order update notifications.'
      params do
        requires :resource_type, type: String
        requires :resource_url, type: String
      end
      post do
        supplier = Supplier.find(params[:supplier_id])

        case params[:resource_type]
        when 'ORDER_NOTIFY'
          Dashboard::Integration::ShipStation::Jobs::ProcessOrderNotifyWebhook.perform_in(3.minutes, supplier.id, params[:resource_url])
        when 'SHIP_NOTIFY'
          Dashboard::Integration::ShipStation::Jobs::ProcessShipNotifyWebhook.perform_in(3.minutes, supplier.id, params[:resource_url])
        when 'FULFILLMENT_SHIPPED'
          Dashboard::Integration::ShipStation::Jobs::ProcessFulfillmentShippedWebhook.perform_in(3.minutes, supplier.id, params[:resource_url])
        end
      rescue ActiveRecord::RecordNotFound
        error!('Page not found', 404)
      rescue StandardError => e
        msg = "[ShipStation Webhook] #{e.message} for supplier #{supplier&.id} \n #{e.backtrace.join("\n")}"
        notify_sentry_and_log(e, msg)
        error!(e.message, 400)
      end
    end
  end
end
