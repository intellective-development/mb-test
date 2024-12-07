class MikmakAPIV1::Entities::Variant < Grape::Entity
  expose :id
  expose :product_id, as: :sku
  expose :brand_name, as: :brand
  expose :product_name
  expose :price
  expose :original_price
  expose :description
  expose :volume do |variant_view|
    String(variant_view.volume)
  end
  expose :volume_attributes do
    expose :volume_value, &:volume_value
    expose :volume_unit, &:volume_unit
    expose :container_count, &:container_count
    expose :container_type, &:container_type
  end
  expose :in_stock
  expose :tags do |variant_view|
    variant_view.tag_names || []
  end
  expose :category_name, as: :category
  expose :product_type_name, as: :type
  expose :product_type_id, as: :type_id
  expose :thumb_url do |variant_view|
    variant_view.image_url(:small)
  end
  expose :image_url do |variant_view|
    variant_view.image_url(:product)
  end
  expose :properties do |variant_view|
    variant_view.properties || []
  end
  expose :supplier_id
  expose :permalink, as: :product_permalink
  expose :product_grouping_permalink do |variant_view|
    variant_view&.product&.product_size_grouping_permalink
  end
  expose :permalink do |variant_view|
    "https://#{ENV['WEB_STORE_URL'] && URI(ENV['WEB_STORE_URL']).host || request.env['HTTP_HOST']}/store/product/#{variant_view&.product&.permalink_with_grouping}"
  end
end
