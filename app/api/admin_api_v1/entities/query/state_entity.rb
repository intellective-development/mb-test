class AdminAPIV1::Entities::Query::StateEntity < Grape::Entity
  expose :slug, as: 'key'
  expose :name
  expose :type
  expose :parent_type,  as: 'parentType'
  expose :parent_key,   as: 'parentId'
  expose :child_type,   as: 'childType'
  expose :children

  def type
    'states'
  end

  def parent_type
    nil
  end

  def parent_key
    nil
  end

  def child_type
    'regions'
  end

  def children
    object.regions.pluck(:slug)
  end
end
