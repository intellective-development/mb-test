class ConsumerAPIV2::Entities::Bundle < Grape::Entity
  expose :id
  expose :description
  expose :category, as: :type
  expose :products
  expose :cocktail, with: Shared::Entities::Cocktails::Cocktail

  def products
    options[:suggestions]
  end
end
