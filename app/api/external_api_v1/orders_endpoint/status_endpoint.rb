class ExternalAPIV1::OrdersEndpoint::StatusEndpoint < ExternalAPIV1
  namespace :orders do
    route_param :number do
      before do
        @order = Order.find_by(number: params[:number])

        error!('Order not found', 404) if @order.nil?
      end

      desc 'Returns tracking details for all shipments.'
      get :status do
        status 200
        present @order, with: ExternalAPIV1::Entities::Order::Status
      end
    end
  end
end
