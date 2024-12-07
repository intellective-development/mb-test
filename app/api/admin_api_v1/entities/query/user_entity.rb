class AdminAPIV1::Entities::Query::UserEntity < Grape::Entity
  expose :id, as: :value
  expose :label

  def label
    object.name
  end
end
