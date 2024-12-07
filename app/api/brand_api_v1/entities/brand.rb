class BrandAPIV1::Entities::Brand < Grape::Entity
  expose :id
  expose :name
  expose :parent_brand_id, if: ->(_brand, _options) { object.parent }
  expose :parent_brand_name, if: ->(_brand, _options) { object.parent }
  expose :product_size_grouping_ids

  private

  def product_size_grouping_ids
    object.product_size_groupings.pluck(:id)
  end

  def parent_brand_id
    object.parent.id
  end

  def parent_brand_name
    object.parent.name
  end
end
