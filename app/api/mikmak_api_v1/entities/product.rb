class MikmakAPIV1::Entities::Product < Grape::Entity
  expose :id, as: :sku
  expose :name
  expose :brand_name, as: :brand
  expose :state
  expose :upc
  expose :thumb_url
  expose :image_url
  expose :volume_unit
  expose :volume_value
  expose :container_count
  expose :container_type
  expose :upc_codes
  expose :product_permalink, &:permalink
  expose :product_size_grouping_permalink, as: :product_grouping_permalink
  expose :permalink

  private

  def permalink
    "https://#{ENV['WEB_STORE_URL'] && URI(ENV['WEB_STORE_URL']).host || request.env['HTTP_HOST']}/store/product/#{object.permalink_with_grouping}"
  end

  def image_url
    object.featured_image(:product)
  end

  def thumb_url
    object.featured_image(:thumb)
  end

  def upc_codes
    (object.additional_upcs << object.upc).compact
  end
end
