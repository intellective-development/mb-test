class PartnerAPIV1::Entities::Product < Grape::Entity
  expose :id
  expose :name
  expose :brand_name, as: :brand
  expose :upc
  expose :thumb_url do |product|
    product.featured_image(:thumb)
  end
  expose :image_url do |product|
    product.featured_image(:product)
  end
  expose :volume_unit
  expose :volume_value
  expose :type, &:hierarchy_type_name
  expose :subtype, &:hierarchy_subtype_name
  expose :category, &:hierarchy_category_name
  expose :container_count
  expose :container_type
  expose :upc_codes do |product|
    (product.additional_upcs << product.upc).compact.uniq
  end
  expose :product_grouping_permalink do |product|
    "https://#{ENV['ASSET_HOST']}/store/product/#{product.product_size_grouping_permalink}".sub('https://https://', 'https://')
  end
  expose :product_permalink do |product|
    "https://#{ENV['ASSET_HOST']}/store/product/#{product.permalink_with_grouping}".sub('https://https://', 'https://')
  end
end
