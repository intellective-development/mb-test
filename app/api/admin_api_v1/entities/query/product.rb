class AdminAPIV1::Entities::Query::Product < Grape::Entity
  expose :id, as: :value
  expose :name, as: :label
end
