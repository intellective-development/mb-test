require_relative 'biz/periods'

class PeriodicService
  def initialize(schedule:, time_zone:, **_options)
    @schedule = schedule
    @time_zone = time_zone
  end

  private

  attr_accessor :time_zone, :schedule, :options
end
