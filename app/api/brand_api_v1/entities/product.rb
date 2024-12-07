class BrandAPIV1::Entities::Product < Grape::Entity
  expose :id, as: :product_id
  expose :permalink
  expose :state
  expose :thumb_url
  expose :image_url
  expose :volume_unit
  expose :volume_value
  expose :container_count
  expose :container_type
  expose :upc_codes

  private

  # JM: This is a horrendous overhead that we are not using.
  def in_stock
    object.variants.none?(&:sold_out?)
  end

  def min_price
    object.variants.minimum(:price)
  end

  def max_price
    object.variants.maximum(:price)
  end

  def upc_codes
    (object.additional_upcs << object.upc).compact
  end

  def image_url
    object.featured_image(:product)
  end

  def thumb_url
    object.featured_image(:thumb)
  end
end
