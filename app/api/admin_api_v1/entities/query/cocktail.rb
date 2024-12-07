class AdminAPIV1::Entities::Query::Cocktail < Grape::Entity
  expose :id, as: :value
  expose :name, as: :label
end
