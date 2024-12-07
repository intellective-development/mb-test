class ZiftyWebhooks < BaseAPI
  helpers do
    params :status_updates do
      # https://zifty-api.readme.io/reference#status-updates-1
      optional :status, type: String, values: %w[Pending Assigned AtPickup InTransit AtDestination Delivered]
      optional :driverName, type: String, desc: 'Name of the driver assigned to the delivery'
      optional :driverPhoneNumber, type: String, desc: 'Phone number of the assigned driver'
      optional :transportType, type: String, desc: 'Vehicle type of assigned driver. Value is always Car for now.'
      optional :latitude, type: Float, desc: 'Current latitude of the driver'
      optional :longitude, type: Float, desc: 'Current longitude of the driver'
      optional :estimatedPickupTime, type: DateTime, desc: 'Latest pick-up time estimate (or the time the actual pick-up occurred if in the past)'
      optional :estimatedDropoffTime, type: DateTime, desc: 'Latest drop-off time estimate (or the time the actual delivery occurred if in the past)'
    end

    params :cancel_delivery do
      # https://zifty-api.readme.io/reference#cancel-delivery-2
      optional :reason, type: String, values: %w[PickupNotReady DestinationUnreachable PackageContents PackageDamage IncompatibleDeliveryMode DriverFailure ServiceOverCommitted DspOtherReason]
    end

    def start_delivery!
      @shipment.create_tracking_detail(reference: params[:delivery_id], carrier: 'Zifty')
      @shipment.start_delivery!
    end

    def order_completed!
      metadata_updates = {}
      metadata_updates[:delivered_at] = params[:estimatedDropoffTime]
      # metadata_updates[:signed_by_name]     = params[:signature_fullname]
      @shipment.metadata.update(metadata_updates)
      @shipment.create_tracking_detail(reference: params[:delivery_id], carrier: 'Zifty')
      @shipment.deliver!
    end

    def create_note(commentable, note, created_by_id)
      commentable.comments.create(note: note, created_by: created_by_id)
    end
  end

  route_param :delivery_id do
    params do
      use :status_updates
    end
    post :status do
      # TODO: When we receive enough data, migrate to DeliveryServiceLog
      Rails.logger.info("[Zifty] Receiving information for webhook /status: #{params[:status]} - #{params}")
      @shipment = Shipment.find params[:delivery_id]
      notes = I18n.translate('notes')
      zifty = RegisteredAccount.zifty.user

      case params[:status]
      when 'Pending'
        # Same status when we created it
      when 'Assigned'
        @shipment.delivery_service_order['driver'] = { name: params[:driverName], phone_number: params[:driverPhoneNumber] }
        @shipment.save!
        note = I18n.translate('notes.order_accepted', driver_name: params[:driverName], phone: params[:driverPhoneNumber])
        create_note(@shipment, note, zifty.id)
      when 'AtPickup'
        create_note(@shipment, notes[:arrived_at_supplier], zifty.id)
      when 'InTransit'
        if @shipment.tracking_detail.present?
          # Zifty calls this endpoint multiple times to update the delivery service GPS coordinates.
          # As we don't handle that ATM, there's nothing to do, just print logs.
          Rails.logger.info "[Zifty] GPS update for shipment #{@shipment.id}: #{params}"
        else
          start_delivery!
          duration_in_words = @shipment.delivery_service_order['duration_in_words']
          note = I18n.translate('notes.start_delivery', estimate: duration_in_words)
          create_note(@shipment, note, zifty.id)
          Segments::SegmentService.from(@shipment.order.storefront).delivery_service_update(@shipment, 'shipment_en_route', nil, @shipment.id)
        end
      when 'AtDestination'
        create_note(@shipment, notes[:arrived_at_consumer], zifty.id)
        Segments::SegmentService.from(@shipment.order.storefront).delivery_service_update(@shipment, 'driver_arrived_to_customer_address', nil, @shipment.id)
      when 'Delivered'
        order_completed!
        create_note(@shipment, notes[:order_completed], zifty.id)
        Segments::SegmentService.from(@shipment.order.storefront).delivery_service_update(@shipment, 'shipment_delivered', nil, @shipment.id)
      end

      { status: 'success' }.to_json
    end

    params do
      use :cancel_delivery
    end
    post :cancel do
      @shipment = Shipment.find params[:delivery_id]
      zifty = RegisteredAccount.zifty.user
      create_note(@shipment, I18n.translate('notes.order_canceled') + " (delivery service id: #{params[:delivery_id]}). Reason: #{params[:reason]}", zifty.id)

      { status: 'success' }.to_json
    end
  end
end
