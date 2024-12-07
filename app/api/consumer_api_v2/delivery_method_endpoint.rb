class ConsumerAPIV2::DeliveryMethodEndpoint < BaseAPIV2
  helpers do
    def delivery_method_expires_in_seconds(delivery_method)
      (delivery_method.next_delivery_stale_at - Time.zone.now.in_time_zone(delivery_method.supplier.timezone)).ceil
    end
  end

  namespace :delivery_method do
    desc 'Returns delivery methods from id', ConsumerAPIV2::DOC_AUTH_HEADER
    route_param :id do
      get :method do
        delivery_method = ShippingMethod.includes(:supplier).find_by(id: params[:id])

        error!('Delivery Method invalid', 400) if delivery_method.nil?

        present delivery_method, with: ConsumerAPIV2::Entities::ShippingMethod
      end
    end
  end
end
