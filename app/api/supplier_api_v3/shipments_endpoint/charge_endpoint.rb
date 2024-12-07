# frozen_string_literal: true

# Endpoint to bulk charge shipments
class SupplierAPIV3::ShipmentsEndpoint::ChargeEndpoint < BaseAPIV3
  namespace :orders do
    desc 'Bulk charge for pre-sale/back-order shipments'
    params do
      requires :uuids, type: Array, allow_blank: false
    end
    put :charge do
      @shipments = Shipment.where(supplier_id: current_supplier_ids.push(current_supplier.id)).where(uuid: params[:uuids])

      error = false
      @shipments.each do |shipment|
        response = Charges::ChargeOrderService.create_and_authorize_charges(shipment.order, [shipment])
        error = true unless response
      end

      error!('Not all shipments were charged successfully.', 400) if error

      @shipments.reload

      present @shipments, with: SupplierAPIV2::Entities::Shipment
    end
  end
end
