class BrandAPIV1::Entities::ProductType < Grape::Entity
  expose :id
  expose :name
  expose :children, with: BrandAPIV1::Entities::ProductType
end
