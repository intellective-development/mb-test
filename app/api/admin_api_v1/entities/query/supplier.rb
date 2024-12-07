class AdminAPIV1::Entities::Query::Supplier < Grape::Entity
  expose :id, as: :value
  expose :label do |supplier|
    name_with_region = supplier.region_name.nil? ? supplier.name : "#{supplier.name} (#{supplier.region_name})"
    name_with_id = "#{name_with_region} (##{supplier.id})"
  end
end
