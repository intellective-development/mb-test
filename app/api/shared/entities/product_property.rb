class Shared::Entities::ProductProperty < Grape::Entity
  expose :display_name, as: :name do |property|
    property.property.display_name
  end
  expose :description, as: :value
end
