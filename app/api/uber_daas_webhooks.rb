# frozen_string_literal: true

# UberDassWebhooks to handle shipment status updates from Uber
class UberDaasWebhooks < BaseAPI
  helpers do
    params :order_details do
      requires :id,      type: String
      optional :courier, type: Hash do
        use :courier_details
      end
    end

    params :courier_details do
      optional :phone_number, type: String
      optional :name,         type: String
    end

    def create_note(note, opts = {})
      message = I18n.translate("notes.#{note}", opts)
      @shipment.comments.create(note: message, created_by: @uber_user_id)
    end

    def delivery_service_update(event)
      segment_service = Segments::SegmentService.from(@shipment.order.storefront)
      segment_service.delivery_service_update(@shipment, event, nil, @reference_id)
    end

    def driver_at_pickup
      last_driver = @shipment.delivery_service_order['courier']
      courier = @data[:courier]
      courier_name = courier[:name]

      return unless last_driver.blank? || last_driver['name'] != courier_name

      @shipment.delivery_service_order['courier'] = courier
      @shipment.save!
      create_note(:driver_at_pickup, { driver_name: courier_name, phone: courier[:phone_number] })
    end

    def shipment_en_route
      create_note('delivery_solutions.pickup_completed')
      delivery_service_update('shipment_en_route')
    end

    def start_delivery
      return unless @shipment.confirmed?

      @shipment.start_delivery!
      duration_in_words = @shipment.delivery_service_order['duration_in_words']
      create_note(:start_delivery, { estimate: duration_in_words })
      delivery_service_update('shipment_dropoff')
    end

    def order_completed
      return unless @shipment.en_route?

      @shipment.metadata.update({ delivered_at: params[:created] })
      @shipment.deliver!
      create_note(:order_completed)
      delivery_service_update('shipment_delivered')
    end
  end

  params do
    requires :kind, type: String, allow_blank: false
    requires :created, type: String, allow_blank: false
    requires :data, type: Hash do
      use :order_details
    end
  end

  post do
    _, type = params[:kind].split('.')

    if type != 'delivery_status'
      Rails.logger.info("UberDaasWebhooks Error: Invalid kind. Params: #{params}")
      return error!('Invalid kind', 400)
    end

    @data = params[:data]
    @reference_id = @data[:id]

    @shipment = Shipment.find_by(external_order_id: @reference_id)
    if @shipment.blank?
      Rails.logger.info("UberDaasWebhooks Error: Shipment not found. Params: #{params}")
      return error!('Order not found', 400)
    end

    @uber_user_id = RegisteredAccount.uber.user.id

    case params[:status]
    when 'pickup'
      driver_at_pickup
    when 'pickup_complete'
      shipment_en_route
    when 'dropoff'
      start_delivery
    when 'delivered'
      order_completed
    when 'canceled'
      create_note(:confirmed_order_cancellation)
    when 'returned'
      create_note('delivery_solutions.order_returned')
    else
      Rails.logger.info("UberDaasWebhooks Error: Invalid status. Params: #{params}")
    end

    { status: 'success' }.to_json
  rescue StandardError => e
    Rails.logger.error("UberDaasWebhooks Error: #{e.message} for shipment #{@shipment&.id || @reference_id}")

    error!(e.message, 400)
  end
end
