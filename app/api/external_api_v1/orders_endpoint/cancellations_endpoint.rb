# frozen_string_literal: true

class ExternalAPIV1
  class OrdersEndpoint
    # Orders Cancellations endpoint
    class CancellationsEndpoint < ExternalAPIV1
      helpers Shared::Helpers::Orders::CancellationParamHelper

      before do
        error!('Order cancellations endpoints are currently disabled', 400) if Feature[:disable_external_api_order_cancellations_endpoint].enabled?
      end

      resources :orders do
        route_param :number do
          after_validation do
            @order = Order.find_by(number: params[:number])

            error!('Order not found', 404) if @order.nil?
          end

          params do
            use :order_cancellation_params
          end

          desc 'Cancels a given order'
          post :cancellations do
            begin
              result = Order::Cancellations::Create.new(order: @order, user: current_user, params: params).call
            rescue ArgumentError => e
              error!({ name: 'OrderCancellationError', message: e.message }, 400)
            end

            error!({ name: 'OrderCancellationError', message: result.error }, 422) unless result.success?

            status 200
            present result.order, with: ExternalAPIV1::Entities::Order
          end
        end
      end
    end
  end
end
