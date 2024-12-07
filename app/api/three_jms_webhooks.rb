class ThreeJMSWebhooks < BaseAPI
  format :json

  helpers Dashboard::Integration::ThreeJMS::Webhooks::OrderUpdateWebhookHelpers

  namespace :order_update do
    desc 'Webhook endpoint for 3JMS order updates.'

    params do
      use :order_update_params
    end

    before do
      authenticate!
    end

    post do
      begin
        shipment = shipment_look_up(params[:retailer_order_id])

        handle_order_status_change(shipment, params)
      rescue ActiveRecord::RecordNotFound
        error!('Order not found', 404)
      rescue StandardError => e
        msg = "[3JMS Webhook] #{e.message} for shipment #{shipment&.id || params[:retailer_order_id]} \n #{e.backtrace.join("\n")}"
        notify_sentry_and_log(e, msg)
        error!(e.message, 400)
      end

      status 200
      { message: 'OK' }
    end

    route_param :supplier_id, type: Integer do
      params do
        use :order_update_params
      end

      desc 'Webhook endpoint for 3JMS order updates for a given supplier.'
      post do
        supplier = Supplier.find(params[:supplier_id])
        shipment = shipment_look_up(params[:retailer_order_id], supplier)

        handle_order_status_change(shipment, params)
      rescue ActiveRecord::RecordNotFound
        error!('Resource not found', 404)
      rescue StandardError => e
        msg = "[3JMS Webhook] #{e.message} for shipment #{shipment&.id || params[:retailer_order_id]} \n #{e.backtrace.join("\n")}"
        notify_sentry_and_log(e, msg)
        error!(e.message, 400)
      end
    end
  end

  namespace :order_internal_note do
    desc 'Webhook endpoint for 3JMS order notes.'
    params do
      use :internal_note_params
    end
    before do
      authenticate!
    end
    post do
      begin
        shipment = shipment_look_up(params[:order])

        message = (params[:user].presence || 'retailer')
        message += " wrote: #{params[:description]}"

        Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, message, true)
      rescue ActiveRecord::RecordNotFound
        error!('Order not found', 404)
      rescue StandardError => e
        msg = "[3JMS Webhook] #{e.message} for shipment #{shipment&.id || params[:order]} \n #{e.backtrace.join("\n")}"
        notify_sentry_and_log(e, msg)

        error!(e.message, 400)
      end

      status 200
      { message: 'OK' }
    end

    route_param :supplier_id, type: Integer do
      params do
        use :internal_note_params
      end

      desc 'Webhook endpoint for 3JMS order notes for a given supplier.'
      post do
        begin
          supplier = Supplier.find(params[:supplier_id])
          shipment = shipment_look_up(params[:order], supplier)

          message = (params[:user].presence || 'retailer')
          message += " wrote: #{params[:description]}"

          Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, message, true)
        rescue ActiveRecord::RecordNotFound
          error!('Order not found', 404)
        rescue StandardError => e
          msg = "[3JMS Webhook] #{e.message} for shipment #{shipment&.id || params[:order]} \n #{e.backtrace.join("\n")}"
          notify_sentry_and_log(e, msg)

          error!(e.message, 400)
        end

        status 200
        { message: 'OK' }
      end
    end
  end
end
