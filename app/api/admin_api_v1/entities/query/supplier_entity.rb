class AdminAPIV1::Entities::Query::SupplierEntity < Grape::Entity
  expose :permalink, as: 'key'
  expose :name
  expose :type
  expose :parent_type,  as: 'parentType'
  expose :parent_key,   as: 'parentId'
  expose :child_type,   as: 'childType'
  expose :children

  def type
    'suppliers'
  end

  def parent_type
    nil
  end

  def parent_key
    nil
  end

  def child_type
    nil
  end

  def children
    []
  end
end
