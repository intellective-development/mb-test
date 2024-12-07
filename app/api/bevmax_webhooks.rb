class BevmaxWebhooks < BaseAPI
  include SentryNotifiable

  format :json
  helpers do
    def authenticate!
      request_token = headers['X-Api-Token']
      valid_tokens = ENV['BEVMAX_WEBHOOK_TOKEN']&.split(';') || ['someth1ng-w3ird-to-n0t-be-m4tch3d']

      error!('Missing or invalid API Token', 401) unless valid_tokens.include?(request_token)
    end

    def create_package(shipment, params)
      tracking_id = params[:carrierTrackingId]

      if shipment.packages.empty?
        package = shipment.packages.create(tracking_number: tracking_id)
        AfterShip::CreateTrackingService.new(package, true).call unless package.nil?
      end
    end

    def create_tracking(shipment, params)
      unless shipment.tracking_detail.nil?
        Rails.logger.info("[Bevmax] Skipped creating tracking for Shipment #{shipment.id} (already exists): #{params}")
        return
      end

      tracking_id = params[:carrierTrackingId]
      tracking_url = params[:trackingUrl]

      if tracking_id && tracking_url
        shipment.create_tracking_detail(reference: tracking_id, carrier: 'Custom')
        shipment.update(delivery_service_order: { id: tracking_id, tracking_url: tracking_url })
      else
        Rails.logger.error("[Bevmax] No tracking details provided for Shipment #{shipment.id}: #{params}")
      end
    rescue StandardError => e
      notify_sentry_and_log(e,
                            "Error on Bevmax Integration: #{e.message}",
                            { shipment: shipment.id, params: params })
    end
  end

  namespace :order_update do
    desc 'Webhook endpoint for BevMax order updates.'
    params do
      requires :orderNumber, type: String
      requires :subOrdersList, type: Array do
        requires :referenceId, type: String
        requires :orderStatusDesc, type: String
        requires :orderStatus, type: Integer
        requires :orderItems, type: Array do
          requires :quantity, type: Integer
          requires :sku, type: String
        end
        optional :trackingUrl, type: String
        optional :caskerCancelReason, type: String
        optional :deliveryTargetTime, type: String
        optional :deliveryDate, type: Date
        optional :cancellationTypeId, type: Integer
        optional :trackingId, type: String
        optional :carrier, type: String
        optional :carrierTrackingId, type: String
      end
    end
    before do
      authenticate!
    end
    post do
      begin
        ORDER_STATUSES = {
          created: 1,
          assigned: 2,
          ready_to_pack: 4,
          cancelled: 5,
          shipped: 6,
          out_for_delivery: 7,
          delivered: 8,
          packed: 9,
          exception: 10,
          in_transit: 12,
          address_check_failed: 15,
          back_order: 18,
          with_carrier: 19
        }.freeze

        order = params[:subOrdersList][0]

        raise error!('BadRequest: subOrder not found', 400) unless order

        external_id = order[:orderNumber]
        shipment = Shipment.find_by!(external_shipment_id: external_id)

        Dashboard::Integration::Bevmax::Notes.add_note(shipment, "<- Order Update: #{order[:orderStatusDesc]}")

        case order[:orderStatus]
        when ORDER_STATUSES[:shipped]
          if shipment.can_transition_to?(:en_route)
            shipment.start_delivery!
            Dashboard::Integration::Bevmax::Notes.add_note(shipment, '<- Shipment en route')
            create_tracking(shipment, order)
            create_package(shipment, order)
          else
            raise StandardError, "Invalid state transition from #{shipment.state} to shipped"
          end
        when ORDER_STATUSES[:delivered]
          if shipment.can_transition_to?(:delivered)
            shipment.deliver!
            Dashboard::Integration::Bevmax::Notes.add_note(shipment, '<- Shipment delivered')
          else
            raise StandardError, "Invalid state transition from #{shipment.state} to delivered"
          end
        when ORDER_STATUSES[:cancelled], ORDER_STATUSES[:back_order]
          Dashboard::Integration::BevmaxDashboard.mark_shipment_canceled(shipment.id)

          if shipment.can_transition_to?(:canceled)
            shipment.cancel!
            Dashboard::Integration::Bevmax::Notes.add_note(shipment, "<- Shipment canceled. #{order[:caskerCancelReason]}")
          else
            raise StandardError, "Invalid state transition from #{shipment.state} to canceled"
          end
        end
      rescue ActiveRecord::RecordNotFound
        error!('Order not found', 404)
      rescue StandardError => e
        Rails.logger.error "[BevMax Webhook] #{e.message} for shipment #{shipment.id}"
        error!(e.message, 400)
      end

      status 200
      { message: 'OK' }
    end
  end
end
