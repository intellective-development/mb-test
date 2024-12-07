class AdminAPIV1::Entities::Query::ProductGroupingEntity < Grape::Entity
  expose :permalink, as: 'key'
  expose :name
  expose :type
  expose :parent_type,  as: 'parentType'
  expose :parent_key,   as: 'parentId'
  expose :child_type,   as: 'childType'
  expose :children

  def type
    'product_groupings'
  end

  def parent_type
    'brands'
  end

  def parent_key
    object.brand.permalink
  end

  def child_type
    nil
  end

  def children
    nil
  end
end
