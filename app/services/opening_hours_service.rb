require_relative 'periodic_service'

class OpeningHoursService < PeriodicService
  def open?(time = Time.current)
    schedule.in_hours?(time)
  end

  def closed?(time = Time.current)
    !open?(time)
  end

  def opens_at(time = Time.current)
    first_period = schedule.periods.between(time, time.advance(weeks: 2)).reject { |period| period.contains?(time) }.first
    first_period&.start_time&.in_time_zone(time_zone)
  end

  def closes_at(time = Time.current)
    first_period = schedule.periods.after(time).first
    first_period&.end_time&.in_time_zone(time_zone)
  end
end
