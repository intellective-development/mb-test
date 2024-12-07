# frozen_string_literal: true

class CheckoutAPIV1
  module Express
    # CheckoutAPIV1::Express::OrdersEndpoint
    class OrdersEndpoint < CheckoutAPIV1
      namespace :express do
        before do
          error!('OOS availability check is currently disabled', 400) if Feature[:disable_oos_availability_check].enabled?
        end

        resources :orders do
          desc 'Finalize order'
          params do
            requires :order_number, type: String, desc: 'Order number', allow_blank: false
          end

          get :approve do
            order = Order.find_by(number: params[:order_number])

            error!({ name: 'SupplierSwitchingForOosProducts::Errors::OrderNotFoundError', message: 'Order not found' }, 404) if order.nil?
            error!({ name: 'SupplierSwitchingForOosProducts::Errors::OrderNotInProgressError', message: 'Order not \'in_progress\'' }, 400) unless order.in_progress?

            result = SupplierSwitchingForOosProducts::FinalizeOrderService.call(order_id: order.id)

            unless result.success?
              Rails.logger.error "[SupplierSwitchingForOosProducts::Errors::OrderFinalizeError] #{result.error} for order ##{order.number}"

              error!({ name: 'SupplierSwitchingForOosProducts::Errors::OrderFinalizeError', message: result.error }, 422)
            end

            redirect '/success'
          end
        end
      end
    end
  end
end
