# frozen_string_literal: true

class ExternalAPIV1
  module Shipments
    # ExternalAPIV1::Shipments::CancellationsEndpoint
    class CancellationsEndpoint < ExternalAPIV1
      helpers Shared::Helpers::Shipments::CancellationParamHelper

      before do
        error!('Shipment cancellation endpoints are currently disabled', 400) if Feature[:disable_external_api_shipment_cancellation_endpoints].enabled?
      end

      resources :shipments do
        route_param :uuid do
          after_validation do
            @shipment = Shipment.find_by(uuid: params[:uuid])

            error!('Shipment not found', 404) if @shipment.nil?
          end

          params do
            use :shipment_cancellation_params
          end

          desc 'Cancels a given shipment'
          post :cancellations do
            begin
              result = Shipment::Cancellations::Create.new(shipment: @shipment, user: current_user, params: params).call
            rescue ArgumentError => e
              error!({ name: 'ShipmentCancellationError', message: e.message }, 400)
            end

            error!({ name: 'ShipmentCancellationError', message: result.error }, 422) unless result.success?

            status 200
            present result.shipment, with: ExternalAPIV1::Entities::Shipment
          end
        end
      end
    end
  end
end
