class ConsumerAPIV2::Entities::Cart < Grape::Entity
  expose :id
  expose :cart_items do |cart|
    items = cart.cart_items.active.with_views.distinct_items.includes(variant: { product: :product_trait })
    ConsumerAPIV2::Entities::CartItem.represent(items, options)
  end
  expose :bundle
  expose :storefront_cart_id
  expose :cart_trait, with: ConsumerAPIV2::Entities::CartTrait, if: ->(cart, _options) { cart.cart_trait }
  expose :cart_amount, with: ConsumerAPIV2::Entities::CartAmount
  expose :address, with: ConsumerAPIV2::Entities::ShippingAddress
  expose :promo_code do |cart|
    cart.promo_code&.code
  end
  expose :gift_cards do |cart|
    cart.gift_cards.pluck(:code)
  end

  def bundle
    ConsumerAPIV2::Entities::Bundle.represent(options[:bundle], options)
  end
end
