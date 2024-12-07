class ConsumerAPIV2::Entities::Region < Grape::Entity
  expose :description
  expose :name
  expose :slug
  expose :cities

  def cities
    object&.cities&.visible&.pluck(:name)
  end
end
