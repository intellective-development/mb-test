class SupplierAPIV2::Entities::WorkingHour < Grape::Entity
  expose :wday
  expose :off
  expose :starts_at
  expose :ends_at
end
