class ExternalAPIV1::Entities::Supplier < Grape::Entity
  expose :display_name, as: :name
end
