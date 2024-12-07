class ConsumerAPIV2::Entities::SchedulingCalendar < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :date,       format_with: :iso_timestamp
  expose :opens_at,   format_with: :iso_timestamp
  expose :closes_at,  format_with: :iso_timestamp
  expose :windows,    with: ConsumerAPIV2::Entities::SchedulingWindow
end
