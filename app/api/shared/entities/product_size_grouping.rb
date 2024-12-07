class Shared::Entities::ProductSizeGrouping < Grape::Entity
  expose :id, :name, :permalink
  expose :brand, with: Shared::Entities::Brands::Brand
end
