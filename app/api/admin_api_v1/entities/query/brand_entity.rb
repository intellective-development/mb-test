class AdminAPIV1::Entities::Query::BrandEntity < Grape::Entity
  expose :permalink, as: 'key'
  expose :name
  expose :type
  expose :parent_type,  as: 'parentType'
  expose :parent_key,   as: 'parentId'
  expose :child_type,   as: 'childType'
  expose :children

  def type
    'brands'
  end

  def parent_type
    nil
  end

  def parent_key
    nil
  end

  def child_type
    'product_groupings'
  end

  def children
    object.product_size_groupings.pluck(:permalink)
  end
end
