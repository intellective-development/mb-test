class Supplier
  module Hours
    def self.included(base)
      base.class_exec do
        has_many :delivery_hours, dependent: :destroy
        accepts_nested_attributes_for :delivery_hours, reject_if: proc { |attributes| attributes['starts_at'].blank? || attributes['ends_at'].blank? }
        validate :delivery_hours_complete?
      end
    end

    def opening_hours
      @opening_hours ||= OpeningHoursService.new(schedule: schedule, time_zone: canonical_time_zone)
    end

    def hours_config
      @hours_config ||= DeliveryHours.days_of_week.map.with_index.with_object({}) do |(day_name, wday), config|
        config[day_name] = hours_for(delivery_hours.find { |delivery_hour| delivery_hour[:wday] == wday })
        config
      end
    end

    def open?(time = Time.zone.now.in_time_zone(timezone))
      opening_hours.open?(time)
    end

    def closed?(time = Time.zone.now.in_time_zone(timezone))
      opening_hours.closed?(time)
    end

    def open_until?(time = Time.zone.now.in_time_zone(timezone) + 10.minutes)
      open? && open?(time)
    end

    def closes_at(time = Time.zone.now.in_time_zone(timezone))
      opening_hours.closes_at(time)
    end

    def opens_at(time = Time.zone.now.in_time_zone(timezone))
      opening_hours.opens_at(time)
    end

    def delivery_hours_changed?
      new_record? || defined?(@delivery_hours_attributes)
    end

    def delivery_hours_attributes=(attributes)
      @delivery_hours_attributes = attributes
      delivery_hours.to_a # load once instead of loading by id
      assign_nested_attributes_for_collection_association(:delivery_hours, attributes)
    end

    private

    def delivery_hours_complete?
      return unless delivery_hours_changed?

      wdays = delivery_hours.map(&:wday)
      7.times do |wday|
        errors.add(:base, "Missing delivery hours for weekday #{wday}") unless wdays.include?(wday)
      end
    end

    def hours_for(day)
      return {} if day.nil?

      parse_time = ->(time) { Time.zone.parse(time).to_s(:time) }
      starts_at  = parse_time[day.starts_at]
      ends_at    = parse_time[day.ends_at]

      # If opening time is the same as closing time, the store is closed so we pass biz and empty hash
      starts_at == ends_at ? {} : { starts_at => ends_at }
    end
  end
end
