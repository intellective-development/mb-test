class Shared::Entities::Cocktails::CocktailImage < Grape::Entity
  expose :id
  expose :image_url do |image|
    image&.photo(:original)
  end
end
