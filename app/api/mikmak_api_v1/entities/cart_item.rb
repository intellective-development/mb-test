class MikmakAPIV1::Entities::CartItem < Grape::Entity
  format_with(:float, &:to_f)

  expose :quantity
  expose :product, with: MikmakAPIV1::Entities::Product
  expose :product_grouping do |item|
    item.product&.product_size_grouping&.get_entity(item.cart.storefront.business)
  end
end
