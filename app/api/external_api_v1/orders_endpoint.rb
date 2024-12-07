class ExternalAPIV1::OrdersEndpoint < ExternalAPIV1
  namespace :orders do
    desc 'Returns an order by order number.'
    route_param :number do
      before do
        @order = Order.find_by(number: params[:number])

        error!('Order not found', 404) if @order.nil?
      end

      get do
        status 200
        present @order, with: ExternalAPIV1::Entities::Order
      end
    end
  end

  mount ExternalAPIV1::OrdersEndpoint::StatusEndpoint
end
