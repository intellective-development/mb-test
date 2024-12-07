class PackagingAPIV1::Entities::Order::Shipment::OrderItem < Grape::Entity
  expose :name
  expose :quantity
  expose :image_url

  private

  def name
    object.product_trait_name
  end

  def image_url
    object.variant.product&.featured_image
  end
end
