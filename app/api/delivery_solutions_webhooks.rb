require 'faraday'

class DeliverySolutionsWebhooks < BaseAPI
  EVENTS = %w[
    REQUEST_RECEIVED REQUEST_FAILED ESTIMATES_RECEIVED ESTIMATES_FAILED
    ORDER_DISPATCHED ORDER_CONFIRMED ORDER_ASSIGNED PICKUP_STARTED
    PICKUP_COMPLETED PICKUP_EXCEPTION OUT_FOR_DELIVERY ORDER_DELIVERED
    ORDER_CANCELLED ORDER_FAILED ORDER_DELAYED ORDER_UNASSIGNED ORDER_RETURNED
    ORDER_UNDELIVERABLE ERROR_EXCEPTION ORDER_REDELIVERY
  ].freeze

  helpers do
    def add_note(commentable, note, created_by_id)
      commentable.comments.create(note: note, created_by: created_by_id)
    end

    def save_log(params, shipment)
      parameters = {
        key: params[:orderId],
        order_id: shipment.order.number,
        store_id: shipment.supplier_id,
        event: params[:event],
        event_date: params[:receivedAt],
        order_status: params[:status],
        driver: params[:driverId],
        delivery_service_id: shipment.supplier.delivery_service_id
      }
      DeliveryServiceLog.create(parameters)
    end

    def signature_receipt_url
      conn = Faraday.new(url: ENV['DELIVERY_SOLUTIONS_URL']) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.response :json
        faraday.headers['X-API-KEY'] = ENV['DELIVERY_SOLUTIONS_KEY']
      end

      resp = conn.get("/api/v1/order/getSignature/#{params[:orderId]}")
      return resp.body['url'] if resp.status == 200
    end
  end

  params do
    optional :driverExternalId,     type: String
    optional :driverId,             type: String
    optional :event,                type: String
    optional :provider,             type: String, allow_blank: false
    optional :receivedAt,           type: String, allow_blank: false
    optional :status,               type: String, allow_blank: false, values: EVENTS
    optional :tenantId,             type: String, allow_blank: false
    optional :trackingNumber,       type: String, allow_blank: false

    requires :note,                 type: String
    requires :orderId,              type: String, allow_blank: false, desc: 'Unique code, used to find aN order.'
    requires :statusUser,           type: String
  end

  post do
    return error!('No Order Id Supplied.', 400) if params[:orderId].blank?

    @shipment = Shipment.find_by(external_order_id: params[:orderId])

    return error!('No Shimpent Associated.', 400) if @shipment.blank?

    save_log(params, @shipment)

    notes = I18n.translate('notes')

    delivery_solutions = RegisteredAccount.delivery_solutions.user

    case params[:status]
    when 'OUT_FOR_DELIVERY'
      @shipment.create_tracking_detail(reference: params[:trackingNumber], carrier: params[:provider])
      @shipment.start_delivery!

      note = I18n.translate('notes.delivery_solutions.order_has_been_picked_up', driverId: params[:driverId]) || params[:event]
    when 'PICKUP_COMPLETED'
      note = notes[:arrived_at_point] || params[:event]
    when 'ORDER_DELIVERED'
      @shipment.create_tracking_detail(reference: params[:trackingNumber], carrier: params[:provider])
      @shipment.deliver!

      note = notes[:order_completed] || params[:event]

      # Signature receipts
      signature_url = signature_receipt_url
      note += " #{I18n.translate('notes.delivery_solutions.signature_url_message', signatureUrl: signature_url)}" if signature_url
    when 'ORDER_UNDELIVERABLE'
      note = notes[:failed_attempt] || params[:event]
    else
      note = I18n.translate("notes.delivery_solutions.#{params.fetch(:status, '').downcase}") || params[:event]
    end

    add_note(@shipment, note, delivery_solutions.id)

    { status: 'success' }.to_json
  end
end
