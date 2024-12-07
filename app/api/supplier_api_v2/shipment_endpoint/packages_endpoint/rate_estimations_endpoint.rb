class SupplierAPIV2::ShipmentEndpoint::PackagesEndpoint::RateEstimationsEndpoint < BaseAPIV2
  include ShipEngineAdapter::Requests

  helpers do
    def ship_engine_adapter
      @ship_engine_adapter ||= ShipEngineAdapter.new
    end
  end

  namespace :order do
    route_param :shipment_id do
      namespace :packages do
        params do
          requires :carrier, type: String, allow_blank: false

          requires :weight, type: Hash, allow_blank: false do
            requires :value,  type: String, allow_blank: false
            requires :unit,   type: String, allow_blank: false
          end

          requires :dimensions, type: Hash, allow_blank: false do
            requires :length, type: String, allow_blank: false
            requires :width,  type: String, allow_blank: false
            requires :height, type: String, allow_blank: false
          end
        end

        before do
          authorize!

          @shipment = current_supplier.shipments.find_by(uuid: params[:shipment_id])
          @shipment ||= Shipment.where(supplier_id: current_supplier_ids).find_by(uuid: params[:shipment_id])

          error!('Order not found', 404) if @shipment.nil?
        end

        desc 'Estimate rate for a given package.'
        post :estimate_rate do
          package = @shipment.packages.build(
            carrier: params[:carrier]
          )

          package.build_ship_engine_detail(
            dimensions: params[:dimensions],
            weight: params[:weight],
            confirmation: 'none'
          )

          begin
            resp = ship_engine_adapter.estimate_rate(package: package)
          rescue ShipEngineAdapter::UnsupportedCarrierError,
                 ShipEngineAdapter::CarrierAccountNotConnectedError,
                 ShipEngineAdapter::UnsuccessfulResponseError,
                 ShipEngineAdapter::CarrierGroundServiceNotAvailableError,
                 EstimateRate::ShipmentAddressNotProvidedError => e

            error!(e.message, 400)
          end

          status 200
          present resp
        end
      end
    end
  end
end
