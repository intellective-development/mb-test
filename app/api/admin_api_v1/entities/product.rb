class AdminAPIV1::Entities::Product < Grape::Entity
  expose :id
  expose :name
  expose :display_price_range, as: :price_range
  expose :description
  expose :item_volume
  expose :brand_name
  expose :prototype_name, as: :category
  expose :product_type_name, as: :varietal
  expose :thumb_url do |product|
    product.featured_image(:small)
  end
  expose :image_url do |product|
    product.featured_image(:product)
  end
  expose :properties, with: Shared::Entities::ProductProperty, &:product_properties
end
