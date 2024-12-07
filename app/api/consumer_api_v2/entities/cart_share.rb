class ConsumerAPIV2::Entities::CartShare < Grape::Entity
  expose :id
  expose :order, with: ConsumerAPIV2::Entities::Order
  expose :share_type
  expose :coupon_code
  expose :address, with: ConsumerAPIV2::Entities::ShippingAddress
  expose :available_cart_share_items, as: :items, with: ConsumerAPIV2::Entities::CartShareItem
  expose :preferred_supplier_ids

  private

  def available_cart_share_items
    object.cart_share_items
          .available # TODO: LD: remove when we can send down no-longer available pgvsv's, dont care if its available
          .includes( # make it more performant
            :product_grouping_variant_store_view,
            product_grouping_variant_store_view: :grouping_view
          )
  end

  def order
    Order.find(object.order_id) if object.order_id
  end
end
