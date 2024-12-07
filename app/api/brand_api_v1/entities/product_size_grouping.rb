class BrandAPIV1::Entities::ProductSizeGrouping < Grape::Entity
  expose :id, as: :product_grouping_id
  expose :name
  expose :description
  expose :brand_name, as: :brand
  expose :parent_brand_name, as: :parent_brand
  expose :hierarchy_category_name, as: :category
  expose :hierarchy_type_name, as: :type
  expose :hierarchy_subtype_name, as: :subtype
  expose :product_type_id
  expose :permalink
  expose :enhanced_content
  expose :meta_keywords, as: :keywords
  expose :product_properties, as: :properties, with: BrandAPIV1::Entities::ProductProperty
  expose :products, as: :products_attributes, with: BrandAPIV1::Entities::Product
  expose :image_url
  expose :thumb_url

  private

  def product_properties
    object.product_properties.includes(:property).select { |pp| ProductSizeGrouping::WHITELIST_PROPERTIES.include? pp.property.identifing_name }
  end

  def image_url
    object.featured_image(:product)
  end

  def thumb_url
    object.featured_image(:small)
  end

  def products
    object.products.where(state: 'active')
  end

  def parent_brand_name
    object.brand.parent&.name
  end

  def enhanced_content
    object.product_content.present?
  end
end
