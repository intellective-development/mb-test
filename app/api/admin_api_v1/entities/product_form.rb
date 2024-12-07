class AdminAPIV1::Entities::ProductForm < Grape::Entity
  expose :id
  expose :name
  expose :description
  expose :volume_value
  expose :volume_unit
  expose :container_count
  expose :container_type
  expose :brand_id do |product|
    [product.brand&.id, product.brand&.name]
  end
  expose :product_properties, as: :properties, with: AdminAPIV1::Entities::ProductProperty
  expose :image_url do |product|
    product.images.first.try(:photo).try(:url, :original)
  end
end

# used for product merging/cloning
