class Shared::Entities::Cocktails::RelatedCocktail < Grape::Entity
  expose :id, :name, :permalink
  expose :images, with: Shared::Entities::Cocktails::CocktailImage
end
