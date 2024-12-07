class AdminAPIV1::Entities::ProductProperty < Grape::Entity
  expose :id
  expose :property_id
  expose :display_name, as: :name do |property|
    property.property.display_name
  end
  expose :description, as: :value
end
