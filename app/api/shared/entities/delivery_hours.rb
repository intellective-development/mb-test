class Shared::Entities::DeliveryHours < Grape::Entity
  expose :wday, as: :day_of_week
  expose :display_name do |delivery_hour|
    Date::DAYNAMES[delivery_hour.wday]
  end
  expose :starts_at_trimmed, as: :opening_time
  expose :ends_at_trimmed, as: :closing_time
end
