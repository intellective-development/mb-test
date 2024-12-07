class SevenElevenWebhooks < BaseAPI
  format :json

  helpers do
    def authenticate!
      request_token = headers['X-Api-Token']
      valid_token = ENV['SEVEN_ELEVEN_NOW_WEBHOOK_TOKEN']

      error!('Missing or invalid API Token', 401) unless request_token == valid_token
    end

    # This searches for inline edits made by 7-Eleven
    # TODO: we need to handle more cases - currently, it searches only for item removal
    def check_for_ile(shipment, params)
      return [] unless params[:data].key?('updated_order')

      notes = []

      params[:data][:updated_order][:items].each do |i|
        # TODO: to cope with multiple types of adjustments we need to verify what is in substitution_option as below
        # if i[:substitution_option].to_s.casecmp("REMOVE") != 0

        next unless i.key?('initial_order_qty')

        sku = i[:item_id]
        quantity = i[:qty]
        quantity_to_replace = i[:initial_order_qty]
        if quantity.positive?
          notes.push("The store set a new quantity (#{quantity}) for item #{i[:item_id]} (#{i[:name]}) - It was #{quantity_to_replace}")
        else
          notes.push("The store completely removed the item #{i[:item_id]} (#{i[:name]}) from this shipment")
        end
        Dashboard::Integration::SevenElevenDashboard.calculate_inline_edits(shipment, sku, quantity, quantity_to_replace)
      end

      notes
    end

    def create_tracking(shipment, params)
      unless shipment.tracking_detail.nil?
        Rails.logger.warn("[7-Eleven] Error while creating tracking for Shipment #{shipment.id} (already exists): #{params}")
        return
      end

      now_id = params.dig(:data, :now_order_id)
      tracking_url = params.dig(:data, :driver, :tracking_url)

      if now_id && tracking_url
        shipment.create_tracking_detail(reference: now_id, carrier: '7NOW')
        shipment.update(delivery_service_order: { id: now_id, tracking_url: tracking_url })
      else
        Rails.logger.warn("[7-Eleven] No tracking details provided for Shipment #{shipment.id}: #{params}")
      end
    rescue StandardError => e
      notify_sentry_and_log(e, e.message, { integration: '7eleven', shipment: shipment.id, params: params })
    end
  end

  namespace :order_status do
    desc 'Webhook endpoint for 7eleven order status updates.'
    params do
      optional :timestamp, type: String
      requires :type, type: String
      requires :event, type: String
      requires :data, type: Hash do
        requires :order_id, type: String
        requires :now_order_id, type: String
        optional :order_type, type: String
        requires :status, type: Symbol, values: %i[submitted accepted processing ready driver_pickup driver_dropoff driver_delivered driver_returned complete canceled failed]
        optional :reason, type: String
        optional :cancel_origin, type: String
        optional :driver, type: Hash do
          optional :phone, type: String
          optional :name, type: String
          optional :image, type: String
          optional :vehicle, type: Hash do
            optional :license_plate_number, type: String
            optional :color, type: String
            optional :make, type: String
            optional :model, type: String
          end
          optional :location, type: Hash
          optional :tracking_url, type: String
        end
      end
      optional :updated_order, type: Hash
    end
    before do
      authenticate!
    end
    post do
      begin
        shipment = Shipment.find_by!(uuid: params[:data][:order_id])
      rescue ActiveRecord::RecordNotFound
        error!('Order not found', 404)
      end

      notes = []

      # notify about progress
      case params[:data][:status]
      when :processing
        Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment processing')
      when :ready
        notes = check_for_ile(shipment, params)
        unless notes.empty?
          ile_note = "-> The following modification(s) in this shipment was/were made by 7-Eleven: \n#{notes.join("\n")}"
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, ile_note, true, [AsanaService::SEVEN_ELEVEN_LINE_ITEM_EDIT_TAG])
        end
        if (shipment.order_items || []).empty?
          shipment.cancel!
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment canceled', true, [AsanaService::SEVEN_ELEVEN_CANCELLATION_TAG])
        else
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment is ready')
        end
      when :failed
        # TECH-5239 - Adding a note when we receive failed status
        Dashboard::Integration::SevenEleven::Notes.add_note(shipment, "<- Failed: #{params[:data][:reason]}")
      when :driver_pickup
        Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Driver is assigned and on his way to pickup the shipment')
      when :driver_dropoff
        reference_id = params.dig(:data, :now_order_id)
        driver_details = "#{params.dig(:data, :driver, :name) || 'unknown'} #{params.dig(:data, :driver, :phone)}".strip
        Dashboard::Integration::SevenEleven::Notes.add_note(shipment, "<- Driver (#{driver_details}) has picked up the shipment and is on his way to customer location")
        create_tracking(shipment, params)
        segment_service = Segments::SegmentService.from(shipment.order.storefront)
        segment_service.delivery_service_update(shipment, 'shipment_en_route', '7-Eleven', reference_id)
      when :driver_delivered
        reference_id = params.dig(:data, :now_order_id)
        Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Driver delivered the shipment to customer')
        segment_service = Segments::SegmentService.from(shipment.order.storefront)
        segment_service.delivery_service_update(shipment, 'shipment_delivered', '7-Eleven', reference_id)
      when :driver_returned
        Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Driver returned - customer refused/unavailable to accept the shipment', true, [AsanaService::SEVEN_ELEVEN_FAILED_DELIVERY_TAG])
      end

      # change order state
      case params[:data][:status]
      when :accepted
        if shipment.can_transition_to?(:confirmed)
          shipment.confirm!
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment confirmed')
        end
      when :driver_dropoff
        if shipment.can_transition_to?(:en_route)
          shipment.start_delivery!
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment en route')
        end
      when :complete, :driver_delivered
        if shipment.can_transition_to?(:delivered)
          shipment.deliver!
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment delivered')
        end
      when :canceled, :driver_returned
        if shipment.can_transition_to?(:canceled)
          shipment.cancel!
          critical = params[:data][:cancel_origin] == 'Store'
          Dashboard::Integration::SevenEleven::Notes.add_note(shipment, '<- Shipment canceled', critical, [AsanaService::SEVEN_ELEVEN_CANCELLATION_TAG])
        end
      end

      status 200

      unless notes.empty?
        shipment.reload
        return { message: 'OK', meta_info: { partner_tax: (shipment.tax_total * 100).to_i } }
      end

      { message: 'OK' }
    end
  end

  namespace :menu_item_status do
    desc 'Webhook endpoint for 7eleven store menu item status updates.'
    params do
      optional :timestamp, type: String
      requires :event, type: String, values: ['menu_item_status']
      requires :data, type: Hash do
        group :items, type: Array do
          requires :store_id, type: String, allow_blank: false
          requires :item_id, type: String, allow_blank: false
          requires :available, type: Boolean
          requires :price, type: Integer, values: 1..9_999_999, desc: 'Price in cents'
        end
      end
    end
    before do
      authenticate!
    end
    post do
      params.dig(:data, :items)&.each do |item|
        supplier = Supplier.find_by(external_supplier_id: item[:store_id])
        next unless supplier

        variant = supplier.variants.find_by(sku: item[:item_id])
        next unless variant

        qty = if item[:available]
                99_999
              else
                0
              end
        variant.update(price: 0.01 * item[:price])
        variant.inventory.update(count_on_hand: qty)

        variant.reindex
      end

      status 200
      { message: 'OK' }
    rescue StandardError => e
      notify_sentry_and_log(e, "[7-Eleven] menu_item_status: #{e.message}")
      error!('Internal server error', 500)
    end
  end

  namespace :store_status do
    desc 'Webhook endpoint for 7eleven store status updates.'
    params do
      optional :timestamp, type: String
      requires :event, type: String
      requires :data, type: Hash do
        group :stores, type: Array do
          requires :store_id, type: String, allow_blank: false
          requires :active, type: Boolean
          optional :reason, types: [String, Boolean]
        end
      end
    end
    before do
      authenticate!
    end
    post do
      stores = params[:data][:stores]

      stores.each do |s|
        begin
          supplier = Supplier.find_by!(dashboard_type: Supplier::DashboardType::SEVEN_ELEVEN, external_supplier_id: s[:store_id])
        rescue ActiveRecord::RecordNotFound
          next # store not found: skipping
        end

        if supplier.external_availability != s[:active]
          supplier.external_availability = s[:active]
          supplier.save
        end
      end

      status 200
      { message: 'OK' }
    end
  end

  namespace :menu_update do
    desc 'Webhook endpoint for 7eleven menu update trigger.'
    params do
      optional :timestamp, type: String
      requires :event, type: String
      requires :data, type: Hash do
        requires :store_id, type: String, allow_blank: false
      end
    end
    before do
      authenticate!
    end
    post do
      store_id = params[:data][:store_id]

      begin
        supplier = Supplier.find_by!(dashboard_type: Supplier::DashboardType::SEVEN_ELEVEN, external_supplier_id: store_id)
      rescue ActiveRecord::RecordNotFound
        error!('Store not found', 404)
      end

      Sidekiq::Client.push('class' => 'ImportStoreWorker', 'queue' => 'inventory_import', 'args' => [supplier.id])

      status 200
      { message: 'OK' }
    end
  end
end
