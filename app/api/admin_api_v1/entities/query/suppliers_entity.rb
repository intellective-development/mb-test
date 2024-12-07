class AdminAPIV1::Entities::Query::SuppliersEntity < Grape::Entity
  present_collection true

  expose :items, as: :suppliers do |object, _|
    object[:items].each_with_object({}) { |supplier, hash| hash[supplier.permalink] = AdminAPIV1::Entities::Query::SupplierEntity.new(supplier) }
  end
end
