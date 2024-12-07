class SupplierAPIV2::Entities::Address < Grape::Entity
  expose :address1
  expose :address2
  expose :city
  expose :state_name, as: :state
  expose :zip_code
  expose :coords do
    expose :latitude, as: :lat
    expose :longitude, as: :lng
  end
end
