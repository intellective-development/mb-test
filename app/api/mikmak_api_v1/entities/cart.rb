class MikmakAPIV1::Entities::Cart < Grape::Entity
  expose :id
  expose :cart_items do |cart|
    items = cart.product_cart_items
    MikmakAPIV1::Entities::CartItem.represent(items)
  end
end
