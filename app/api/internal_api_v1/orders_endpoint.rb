# frozen_string_literal: true

class InternalAPIV1
  # InternalAPIV1::OrdersEndpoint
  class OrdersEndpoint < BaseAPIV1
    format :json

    resource :orders do
      desc 'Returns a list of orders filtered by date and state'
      params do
        # Filtering
        requires :storefront_id, type: Integer, desc: 'Storefront ID'
        optional :start_date, type: Date, desc: 'Start date'
        optional :end_date, type: Date, desc: 'End date'
        optional :state, type: String, desc: 'Order state', default: 'delivered'
        # Pagination
        optional :page, type: Integer, default: 1
        optional :per_page, type: Integer, default: 20
        # Sorting
        optional :sort_dir, type: String, regexp: /^(asc|desc)$/, default: 'desc'
      end
      get do
        start_date = params[:start_date].presence
        end_date = params[:end_date].presence

        orders = Order.includes(shipments: [
                                  :shipping_method,
                                  :shipment_amount,
                                  :packages,
                                  { comments: %i[author user] },
                                  { supplier: %i[parent supplier_logos] },
                                  { order_items: [{ variant: { product: [:product_trait] } }] }
                                ]).where(storefront_id: params[:storefront_id])
        orders.where!(updated_at: start_date..end_date) if start_date.present? || end_date.present?
        orders.where!(state: params[:state].split(',').map(&:strip)) if params[:state].present?

        orders.order(updated_at: params[:sort_dir].to_sym)
        total_items = orders.count

        orders = orders.offset((params[:page] - 1) * params[:per_page]).limit(params[:per_page])

        {
          items: InternalAPIV1::Entities::Order.represent(orders),
          pagination: {
            prev: params[:page] > 1 ? (params[:page] - 1) : 0,
            next: orders.count.positive? && orders.count == params[:per_page] ? (params[:page] + 1) : 0,
            current: params[:page],
            limit: params[:per_page],
            total: total_items || 0
          }
        }
      end

      route_param :number do
        desc 'Returns a specific order info'
        params do
          requires :number, type: String
        end
        get do
          order = Order.includes(:user, shipments: [
                                   :shipping_method,
                                   :shipment_amount,
                                   :packages,
                                   { comments: %i[author user] },
                                   { supplier: %i[parent supplier_logos] },
                                   { order_items: [{ variant: { product: [:product_trait] } }] }
                                 ]).where(number: params[:number]).first
          error!('Invalid Order Number', 400) if order.nil?
          present :order, order, with: InternalAPIV1::Entities::Order
        end
      end
    end
  end
end
