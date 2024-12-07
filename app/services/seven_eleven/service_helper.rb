# frozen_string_literal: true

module SevenEleven
  # ServiceHelper is a class that contains helper methods for SevenEleven services
  class ServiceHelper
    def self.convert_ampm_to_24h(time_ampm)
      return if time_ampm.nil?

      time, ampm = time_ampm.downcase.split
      hours, minutes = time.split(':')
      hours = ampm == 'pm' && hours.to_i < 12 ? hours.to_i + 12 : hours
      hours = '00' if ampm == 'am' && hours.to_i == 12
      "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}"
    end
  end
end
