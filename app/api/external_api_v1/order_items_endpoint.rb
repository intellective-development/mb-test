# frozen_string_literal: true

class ExternalAPIV1
  # ExternalAPIV1::OrderItemsEndpoint
  class OrderItemsEndpoint < ExternalAPIV1
    before do
      error!('Order items endpoints are currently disabled', 400) if Feature[:disable_external_api_order_items_endpoints].enabled?
    end

    resource :order_items do
      route_param :id do
        before do
          @order_item = OrderItem.find_by(id: params[:id])

          error!('Order item not found', 404) if @order_item.nil? || order_item_from_different_storefront?(@order_item)
        end

        desc 'Returns all substitution options for a given order item'
        get :substitution_options do
          result = OrderItems::SubstitutionOptions::List.new(order_item: @order_item).call

          status 200
          present result.substitution_options, with: ExternalAPIV1::Entities::OrderItem::SubstitutionOption
        end

        params do
          optional :quantity, type: Integer, desc: 'Quantity', allow_blank: false
        end

        delete do
          begin
            result = OrderItems::Remove.call(order_item: @order_item, user: current_user, quantity: params[:quantity])
          rescue ArgumentError => e
            error!({ name: 'OrderItemRemovalError', message: e.message }, 400)
          end

          error!({ name: 'OrderItemRemovalError', message: result.error }, 422) unless result.success?

          status 200
          present message: 'Item removed'
        end
      end
    end

    helpers do
      def order_item_from_different_storefront?(order_item)
        order_item.order.storefront_id != current_user&.storefront_id
      end
    end
  end
end
