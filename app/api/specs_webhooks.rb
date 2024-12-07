class SpecsWebhooks < BaseAPI
  format :json

  helpers do
    def authenticate!
      request_token = headers['X-Api-Token']
      valid_token = ENV['SPECS_WEBHOOK_TOKEN']

      error!('Missing or invalid API Token', 401) unless request_token == valid_token
    end

    def update_order(shipment, params)
      return unless params[:data].key?('updated_order')

      notes = []

      params[:data][:updated_order].each do |i|
        init_sku = i['initial_primary_upc']
        new_sku = i['primary_upc']
        init_qty = i['initial_qty']
        new_qty = i['qty']

        existing_item_sku = init_sku || new_sku
        existing_order_item = shipment.order_items.find { |oi| oi&.variant&.sku == existing_item_sku }

        error!("Could not find item #{existing_item_sku} in specified order.") if existing_order_item.nil?
        error!("Could not find item #{new_sku}.") unless Variant.where(supplier_id: shipment.supplier.id, sku: new_sku).exists?

        if (!init_sku.nil? && init_sku != new_sku) || (!init_qty.nil? && init_qty != new_qty)
          Dashboard::Integration::SpecsDashboard.apply_modification(shipment, existing_order_item, new_sku || init_sku, new_qty, init_qty || new_qty)
        else
          next
        end

        if !init_sku.nil? && init_sku != new_sku
          notes.push("substituted item #{existing_order_item&.variant&.name} (#{existing_order_item&.quantity} qty) with #{i['name']} (#{new_qty} qty)")
        elsif !init_qty.nil? && init_qty != new_qty
          if new_qty.zero?
            notes.push("removed item #{existing_order_item&.variant&.name}")
          else
            notes.push("changed quantity of #{existing_order_item&.variant&.name} from #{init_qty} to #{new_qty}")
          end
        end
      end

      unless notes.empty?
        ile_note = "-> The following modification(s) in this shipment was/were made: \n#{notes.join("\n")}"
        Dashboard::Integration::Specs::Notes.add_note(shipment, ile_note)
      end
    end
  end

  namespace :order_status do
    desc 'Webhook endpoint for Specs order status updates.'
    params do
      optional :timestamp, type: String
      requires :data, type: Hash do
        requires :order_id, type: String
        requires :status, type: Symbol, values: %i[ready_for_pickup canceled returned]
        optional :updated_order, type: Array do
          optional :initial_primary_upc, type: String, allow_blank: false
          requires :primary_upc, type: String, allow_blank: false
          requires :name, type: String, allow_blank: false
          requires :price, type: Float
          optional :initial_qty, type: Integer, allow_blank: false
          requires :qty, type: Integer, allow_blank: false
        end
      end
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

      # notify about progress
      case params[:data][:status]
      when :ready_for_pickup
        Dashboard::Integration::Specs::Notes.add_note(shipment, '<- Shipment ready for pickup')
      when :returned
        Dashboard::Integration::Specs::Notes.add_note(shipment, "<- Spec's confirmed return of the shipment. You can now initiate redelivery or cancel the order if you haven't already.", true)
      end

      # change order state
      case params[:data][:status]
      when :ready_for_pickup
        if shipment.can_transition_to?(:confirmed)
          update_order(shipment, params)
          shipment.confirm!
          Dashboard::Integration::Specs::Notes.add_note(shipment, '<- Shipment confirmed')
        end
      when :canceled
        if shipment.can_transition_to?(:canceled)
          shipment.cancel!
          Dashboard::Integration::Specs::Notes.add_note(shipment, '<- Shipment canceled', true)
        end
      end

      status 200
      { message: 'OK' }
    end
  end

  namespace :order_modification do
    desc 'Webhook endpoint for initiating Specs order modifications.'
    params do
      optional :timestamp, type: String
      requires :data, type: Hash do
        requires :order_id, type: String
        requires :url, type: String
      end
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

      Dashboard::Integration::Specs::Notes.add_note(shipment, "<- Spec's initiated required order modifications.\nConsult with customer and act on modifications: #{params[:data][:url]}", true)

      status 200
      { message: 'OK' }
    end
  end
end
