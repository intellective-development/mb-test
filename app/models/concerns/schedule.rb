module Schedule
  class InvalidTimeZoneError < TZInfo::InvalidTimezoneIdentifier
    def initialize(time_zone, original)
      super "Invalid TimeZone #{time_zone.inspect}\n#{original.class}: #{original}"
    end
  end

  # Adds the class method time_zone_method which allows you to set the name of the method
  # to call on the object to get the time_zone. For supplier that is timezone for
  # shipping_method it is supplier_timezone.
  def self.included(base) # :nodoc:
    base.extend(ClassMethod)
    base.class_exec do
      class << self
        attr_accessor :time_zone_method_name
      end
    end

    base.time_zone_method_name = :time_zone
  end

  # Finds the time_zone and caches the canonical version
  def canonical_time_zone
    time_zone = public_send(self.class.time_zone_method_name)
    @time_zone ||= ActiveSupport::TimeZone.find_tzinfo(time_zone).canonical_identifier
  rescue TZInfo::InvalidTimezoneIdentifier => e
    raise InvalidTimeZoneError.new(time_zone, e)
  end

  # provides a cached version of the Biz schedule avoids multiple services building
  # their own schedule.
  def schedule
    @schedule ||= Biz::Schedule.new do |config|
      config.hours     = filtered_hours_config
      config.time_zone = canonical_time_zone
      config.holidays  = Array(upcoming_holidays)
      # TECH-4370 allow creating holidays by shipping type.
      config.holidays  = Array(upcoming_holidays_by_shipping_type(shipping_type)) if respond_to?(:shipping_type)
      config.breaks    = upcoming_breaks if respond_to?(:upcoming_breaks)
    end
  end

  def filtered_hours_config(_generate_placeholder = true)
    # Biz assumes 00:00-00:00 spans an entire day, so we remove these values
    # from the hours hash. We also need to check that the hours config is not
    # empty as this will cause errors at runtime, in this case we insert a fake
    # entry.
    config = hours_config.reject { |_k, v| v.keys.first == v.values.first }
    config = { sun: { '00:00' => '00:01' } } if config.empty?
    config
  end

  module ClassMethod
    def time_zone_method(name)
      self.time_zone_method_name = name.to_sym
    end
  end
end
