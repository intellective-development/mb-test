class CartWheelWebhooks < BaseAPI
  helpers do
    def create_note(note)
      @shipment.comments.create(note: note, created_by: @cart_wheel.id)
    end

    def start_delivery!
      @shipment.start_delivery! unless @shipment.state == 'en_route'
    end

    def order_completed!
      metadata_updates = {}
      metadata_updates[:delivered_at] = Time.now
      @shipment.metadata.update(metadata_updates)
      @shipment.deliver! unless @shipment.state == 'delivered'
    end
  end

  resource :driver do
    route_param :driver_id do
      params do
        requires :lat, type: String
        requires :lon, type: String
      end

      post :coordinates do
        { status: 'success' }.to_json
      end
    end
  end

  resource :order do
    route_param :external_order_id do
      before do
        @shipment = Shipment.find_by(external_order_id: params[:external_order_id])
        error!({ status: 'error', message: 'Shipment not found' }, 400) unless @shipment

        @cart_wheel = RegisteredAccount.cart_wheel.user
        error!({ status: 'error', message: 'User not found' }, 400) unless @cart_wheel
      end

      params do
        requires :status, type: String
      end
      post :status do
        notes = I18n.translate('notes')
        segment_service = Segments::SegmentService.from(@shipment.order.storefront)

        case params[:status]
        when 'accepted'
          status = CartWheelService.new(@shipment).get_order_status(params[:external_order_id])
          note = I18n.translate('notes.order_accepted', driver_name: status.dig('driver', 'name'), phone: status.dig('driver', 'phone'))
          create_note(note)
          @shipment.accept!
        when 'picked_up'
          start_delivery!
          create_note(notes[:start_delivery])
          segment_service.delivery_service_update(@shipment, 'shipment_en_route', nil, params[:external_order_id])
        when 'completed'
          order_completed!
          create_note(notes[:order_completed])
          segment_service.delivery_service_update(@shipment, 'shipment_delivered', nil, params[:external_order_id])
        when 'unassigned'
          create_note(I18n.translate('notes.order_canceled_republished', delivery_service: 'Cart Wheel'))
          @shipment.exception!
        when 'at_dropoff'
          create_note(notes[:at_dropoff])
        when 'at_pickup'
          create_note(notes[:at_pickup])
        when 'canceled'
          create_note("#{notes[:order_canceled_successfully]} (CartWheel)")
        else
          Rails.logger.error("[CartWheel] Received unexpected status update: #{params[:status]}")
        end
        { status: 'success' }.to_json
      end

      params do
        requires :tracking_url, type: String
      end
      post :details do
        external_order_id = params[:external_order_id]

        @shipment.create_tracking_detail(reference: external_order_id, carrier: 'CartWheel')
        @shipment.update(delivery_service_order: { id: external_order_id, tracking_url: params[:tracking_url] })

        { status: 'success' }.to_json
      end
    end
  rescue StandardError => e
    notify_sentry_and_log(e, "CartWheel Webhook Error #{e.class.name}: #{e.message}", { tags: { webhook_params: params.to_json } })
  end
end
