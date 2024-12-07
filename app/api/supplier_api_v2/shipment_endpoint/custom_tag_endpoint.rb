class SupplierAPIV2::ShipmentEndpoint::CustomTagEndpoint < BaseAPIV2
  namespace :order do
    params do
      requires :shipment_id, type: String
    end

    before do
      authorize!

      @shipment   = current_supplier.shipments.includes(:shipment_amount).find_by(uuid: params[:shipment_id])
      @shipment ||= Shipment.includes(:shipment_amount).where(supplier_id: current_supplier_ids).find_by(uuid: params[:shipment_id])

      error!('Order not found', 404) if @shipment.nil?
    end

    route_param :shipment_id do
      namespace :custom_tags do
        params do
          requires :custom_tag_id, type: Integer
        end

        desc 'Assign custom tag for and order'
        post :assign do
          @shipment.custom_tag_shipments.create(custom_tag_id: params[:custom_tag_id])

          present @shipment, with: SupplierAPIV2::Entities::Shipment
        end

        desc 'Unassign custom tag for and order'
        post :unassign do
          @shipment.custom_tag_shipments.find_by(custom_tag_id: params[:custom_tag_id])&.destroy

          present @shipment, with: SupplierAPIV2::Entities::Shipment
        end
      end
    end
  end
end
