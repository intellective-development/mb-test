class ConsumerAPIV2::Entities::Variant < Grape::Entity
  expose :id
  expose :product_display_name, as: :name
  expose :strip_brand_from_name, as: :product_name
  expose :price do |variant|
    variant.price.to_f.round_at(2)
  end
  expose :original_price do |variant|
    variant.original_price.to_f.round_at(2)
  end
  expose :product_extended_description, as: :description
  expose :sku
  expose :item_volume, as: :volume
  expose :volume_attributes do
    expose :volume_value do |variant|
      variant.product.volume_value
    end
    expose :volume_unit do |variant|
      String(variant.product.volume_unit).downcase
    end
    expose :container_count do |variant|
      variant.product.container_count
    end
    expose :container_type do |variant|
      String(variant.product.container_type).downcase
    end
  end
  expose :product_brand_name, as: :brand
  expose :quantity_available, as: :in_stock
  expose :tags do |variant|
    variant.product_size_grouping.tag_list
  end
  expose :category do |variant|
    variant.product.hierarchy_category_name
  end
  expose :varietal, as: :type do |variant|
    variant.product.product_type_name
  end
  expose :type_id do |variant|
    variant.product.product_type.id
  end
  expose :thumb_url do |variant|
    variant.featured_image(:small)
  end
  expose :image_url do |variant|
    variant.featured_image(:product)
  end
  expose :properties, with: Shared::Entities::ProductProperty do |variant|
    variant.product.product_properties.visible
  end
  expose :supplier_id
  expose :permalink
end
