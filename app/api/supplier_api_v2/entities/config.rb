class SupplierAPIV2::Entities::Config < Grape::Entity
  expose :email_tip do |object|
    object.config['email_tip'] || false
  end
end
