class AdminAPIV1::Entities::Query::RegionEntity < Grape::Entity
  expose :slug, as: 'key'
  expose :name
  expose :type
  expose :parent_type,  as: 'parentType'
  expose :parent_key,   as: 'parentId'
  expose :child_type,   as: 'childType'
  expose :children

  def type
    'regions'
  end

  def parent_type
    'states'
  end

  def parent_key
    object.state&.slug
  end

  def child_type
    nil
  end

  def children
    []
  end
end
