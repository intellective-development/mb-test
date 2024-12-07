# frozen_string_literal: true

class ExternalAPIV1
  module Shipments
    # ExternalAPIV1::Shipments::OrderAdjustmentsEndpoint
    class OrderAdjustmentsEndpoint < ExternalAPIV1
      helpers Shared::Helpers::OrderAdjustmentHelper, Shared::Helpers::OrderAdjustmentParamHelper

      before do
        error!('Shipments order adjustments endpoints are currently disabled', 400) if Feature[:disable_external_api_shipments_order_adjustments_endpoint].enabled?
      end

      resources :shipments do
        route_param :uuid do
          after_validation do
            @shipment = Shipment.find_by(uuid: params[:uuid])

            error!('Shipment not found', 404) if @shipment.nil?
          end

          params do
            use :order_adjustment_params
          end

          resources :order_adjustments do
            desc 'Creates a new order adjustment for a given shipment'
            post do
              @create_service = OrderAdjustmentCreationService.new(@shipment, permitted_order_adjustment_params(params, current_user))

              if @create_service.process!
                @order_adjustment = @create_service.records.first

                Segment::SendOrderUpdatedEventWorker.perform_async(@shipment.order.id, :order_adjustment_created)

                status 201
                present @order_adjustment, with: ExternalAPIV1::Entities::OrderAdjustment
              else
                @order_adjustment = @create_service.error_record

                error!({ name: 'OrderAdjustmentError', message: @order_adjustment.errors }, 422)
              end
            end
          end
        end
      end
    end
  end
end
