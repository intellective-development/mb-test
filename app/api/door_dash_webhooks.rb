class DoorDashWebhooks < BaseAPI
  helpers do
    params :delivery_details do
      requires :id,                   type: Integer
      requires :external_delivery_id, type: String
      requires :updated_at,           type: String
      requires :status,               type: String
      requires :dropoff_address,      type: Hash do
        requires :city,               type: String
        requires :state,              type: String
        requires :street,             type: String
        requires :unit,               type: String
        requires :zip_code,           type: String
      end
      optional :dasher,               type: Hash do
        requires :id,                 type: Integer
        requires :first_name,         type: String
        requires :last_name,          type: String
        requires :phone_number,       type: String
      end
    end

    def start_delivery!
      @shipment.create_tracking_detail(reference: params[:external_delivery_id], carrier: 'DoorDash')
      @shipment.start_delivery! unless @shipment.state == 'en_route' # started by supplier
    end

    def parse_time(time)
      Time.parse(time)
    rescue StandardError => e # time param from DD might not be correctly formatted and understood by our app, nothing to do
      time
    end

    def order_completed!
      if @shipment.metadata
        metadata_updates = {}
        metadata_updates[:delivered_at] = parse_time(params[:updated_at])
        @shipment.metadata.update(metadata_updates)
      else
        Rails.logger.error "[DoorDash] Shipment #{@shipment.id} hasn't have ShipmentMetadata"
      end
      @shipment.create_tracking_detail(reference: params[:external_delivery_id], carrier: 'DoorDash')
      @shipment.deliver! unless @shipment.state == 'delivered' # marked by suppliers
    end

    def create_note(commentable, note, created_by_id)
      commentable.comments.create(note: note, created_by: created_by_id)
    end

    def save_log(params)
      log_data = {
        key: params.dig(:delivery, :external_delivery_id),
        order_id: params.dig(:delivery, :id),
        event: params[:event_category],
        event_date: params.dig(:delivery, :updated_at),
        order_status: params.dig(:delivery, :status),
        point: params.dig(:delivery, :dropoff_address),
        delivery_service_id: @shipment.supplier.delivery_service_id,
        driver: params.dig(:delivery, :dasher)
      }
      DeliveryServiceLog.create(log_data)
    end

    def notify_segment(event, params)
      reference_id = params.dig(:delivery, :external_delivery_id)
      Segments::SegmentService.from(@shipment.order.storefront).delivery_service_update(@shipment, event, nil, reference_id)
    end
  end

  params do
    requires :delivery, type: Hash do
      use :delivery_details
    end
    requires :event_category, type: String, allow_blank: false
  end

  post do
    @shipment = Shipment.find_from_delivery_id(params.dig(:delivery, :external_delivery_id), 'DoorDash')
    save_log(params)

    notes = I18n.translate('notes')
    door_dash = RegisteredAccount.door_dash.user

    case params[:event_category]
    when 'delivery_created'
      if @shipment.delivery_service_order.nil?
        create_note(@shipment, notes[:delivery_order_created], door_dash.id)
        delivery_params = params[:delivery]
        delivery_params['id'] = delivery_params['delivery_id'] if delivery_params['id'].nil? && delivery_params['delivery_id'].present?
        @shipment.delivery_service_order = delivery_params
        @shipment.save!
      end
    when 'dasher_confirmed'
      @shipment.delivery_service_order['driver'] = params.dig(:delivery, :dasher)
      @shipment.save!
      driver_name = "#{params.dig(:delivery, :dasher, :first_name)} #{params.dig(:delivery, :dasher, :last_name)}"
      note = I18n.translate('notes.order_accepted', driver_name: driver_name, phone: params.dig(:delivery, :dasher, :phone_number))
      create_note(@shipment, note, door_dash.id)
    when 'dasher_confirmed_store_arrival'
      note = notes[:arrived_at_supplier]
      create_note(@shipment, note, door_dash.id)
    when 'dasher_picked_up'
      start_delivery!
      duration_in_words = @shipment.delivery_service_order['duration_in_words']
      note = I18n.translate('notes.start_delivery', estimate: duration_in_words)
      create_note(@shipment, note, door_dash.id)
      notify_segment('shipment_en_route', params)
    when 'dasher_confirmed_consumer_arrival'
      note = notes[:arrived_at_consumer]
      create_note(@shipment, note, door_dash.id)
      notify_segment('driver_arrived_to_customer_address', params)
    when 'dasher_dropped_off'
      order_completed!
      note = notes[:order_completed]
      create_note(@shipment, note, door_dash.id)
      notify_segment('shipment_delivered', params)
    when 'delivery_cancelled'
      create_note(@shipment, notes[:order_canceled_successfully] + " (delivery service id: #{params.dig(:delivery, :id)})", door_dash.id)
    when 'dasher_enroute_to_pickup', 'enroute_to_pickup'
      # These notifications were disabled because of TECH-3711
      # pickup_time = params.dig(:delivery, :estimated_pickup_time)
      # note = I18n.translate('notes.enroute_to_pickup', estimated_pickup_time: pickup_time.in_time_zone(@shipment.supplier.timezone))
      # create_note(@shipment, note, door_dash.id)
    when 'dasher_enroute_to_dropoff', 'enroute_to_dropoff'
      # These notifications were disabled because of TECH-3711
      # dropoff_time = params.dig(:delivery, :estimated_delivery_time)
      # note = I18n.translate('notes.enroute_to_dropoff', estimated_dropoff_time: dropoff_time.in_time_zone(@shipment.supplier.timezone))
      # create_note(@shipment, note, door_dash.id)
    when 'enroute_to_return', 'dasher_enroute_to_return', 'dasher_dropped_off_return'
      note = notes[:enroute_to_cancel]
      create_note(@shipment, note, door_dash.id)
      exception_metadata = { type: 'failed_delivery', description: 'failed_delivery', metadata: { failed_delivery: note } }
      @shipment.transition_to!(:exception, exception_metadata)
    when 'driver_batched'
      create_note(@shipment, notes[:driver_batched], door_dash.id)
    else
      Rails.logger.error("[DoorDash] Received unexpected event webhook update: Event #{params[:event_category]} with params #{params}")
    end
    { status: 'success' }.to_json

  rescue StandardError => e
    Rails.logger.error("DoorDash Webhook Error #{e.class.name}: #{e.message}")
  end
end
