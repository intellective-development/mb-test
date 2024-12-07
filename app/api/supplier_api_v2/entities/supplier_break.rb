class SupplierAPIV2::Entities::SupplierBreak < Grape::Entity
  expose :date do |current_break|
    current_break.date.to_date
  end
  expose :start_time do |current_break|
    current_break.start_time.in_time_zone(current_break.supplier.timezone).iso8601
  end
  expose :end_time do |current_break|
    current_break.end_time.in_time_zone(current_break.supplier.timezone).iso8601
  end
end
