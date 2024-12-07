class AdminAPIV1::Entities::Inventory::SupplierOption < Grape::Entity
  expose :id
  expose :name
  expose :dashboard_type
  expose :external_supplier_id
  expose :region_name do |supplier|
    supplier.region&.name
  end
  expose :active
  expose :import_stale_file_time_frame
end
