class SupplierAPIV2::Entities::Settings < Grape::Entity
  expose :working_hours, with: SupplierAPIV2::Entities::WorkingHour
end
