class AdminAPIV1::Entities::ActivationHit < Grape::Entity
  expose :id
  expose :title do |product|
    "#{product.name} - #{product.item_volume}"
  end
  expose :subtitle do |product|
    [
      product.hierarchy_category_name,
      product.hierarchy_type_name,
      product.hierarchy_subtype_name
    ].compact.join(' > ')
  end
  expose :value do |product|
    product.featured_image(:product)
  end
end
