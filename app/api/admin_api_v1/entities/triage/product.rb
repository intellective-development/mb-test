class AdminAPIV1::Entities::Triage::Product < Grape::Entity
  expose :id
  expose :title do |product|
    "#{product.name} - #{product.item_volume}"
  end
  expose :hierarchy_category_name
  expose :hierarchy_type_name
  expose :hierarchy_subtype_name
  expose :image_url do |product|
    product.image_urls(:product)
  end
  expose :variant_count do |product|
    product.variants.self_active.count
  end
  expose :description
  expose :permalink
end
