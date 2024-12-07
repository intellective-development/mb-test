class SupplierAPIV2::Entities::Report < Grape::Entity
  expose :id
  expose :state
  expose :report_url
  expose :report_type
  expose :start_date
  expose :end_date
  expose :open_orders
  expose :shipping_only
  expose :delivery_only
end
