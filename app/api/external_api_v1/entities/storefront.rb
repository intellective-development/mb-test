class ExternalAPIV1::Entities::Storefront < Grape::Entity
  expose :uuid
  expose :name
  expose :slug
end
