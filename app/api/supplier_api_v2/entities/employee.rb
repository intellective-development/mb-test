class SupplierAPIV2::Entities::Employee < Grape::Entity
  expose :id
  expose :active
  expose :first_name
  expose :last_name
  expose :email
  expose :roles
end
