class Shared::Entities::Cocktails::Cocktail < Grape::Entity
  expose :id, :permalink, :name, :serves, :description, :instructions, :active
  expose :tag_list, as: :tags
  expose :images, with: Shared::Entities::Cocktails::CocktailImage
  expose :thumbnail, with: Shared::Entities::Tools::ToolIcon
  expose :ingredients, with: Shared::Entities::Cocktails::Ingredient
  expose :tools, with: Shared::Entities::Tools::Tool
  expose :brand, with: Shared::Entities::Cocktails::CocktailBrand
  expose :related_cocktails, with: Shared::Entities::Cocktails::RelatedCocktail
end
