class ConsumerAPIV2::Entities::SchedulingWindow < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :start_time, format_with: :iso_timestamp
  expose :end_time, format_with: :iso_timestamp
end
