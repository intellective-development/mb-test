class AdminAPIV1::Entities::Inventory::SupplierStats < Grape::Entity
  expose :current_active do |supplier|
    supplier.variants.active.count
  end
  expose :current_in_stock do |supplier|
    supplier.variants.active.available.count
  end
end
