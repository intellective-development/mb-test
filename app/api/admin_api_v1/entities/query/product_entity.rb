class AdminAPIV1::Entities::Query::ProductEntity < Grape::Entity
  expose :id, as: :value
  expose :label

  def label
    object.display_name_with_id
  end
end
