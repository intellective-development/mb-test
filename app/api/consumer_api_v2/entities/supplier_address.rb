class ConsumerAPIV2::Entities::SupplierAddress < Grape::Entity
  expose :name
  expose :id
  expose :address, if: ->(object, _options) { object.address } do |object, _options|
    ConsumerAPIV2::Entities::Address.represent(object.address, supplier: true)
  end
  expose :type do |object, _options|
    object&.supplier_type&.name
  end
end
