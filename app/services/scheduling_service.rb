require_relative 'periodic_service'
require_relative 'biz/delivery_slots'

class SchedulingService < PeriodicService
  def initialize(schedule:, time_zone:, **options)
    super

    Time.use_zone(time_zone) do
      @options  = options
      @origin   = calculate_origin(options[:origin] || Time.zone.now)
      @terminus = calculate_terminus(options[:promo])
      @duration = Biz::Duration.minutes(options[:duration] || 120)
      @offset   = calculate_offset(options[:offset] || 60)
    end
  end

  def scheduling_windows
    slots
      .group_by { |slot| in_zone(slot.start_time).to_date }
      .map { |date, slots| as_windows(date, slots) }
  end

  def next_scheduling_window
    slots.map { |slot| as_window(slot) }.first
  end

  private

  attr_reader :origin, :duration, :offset, :terminus, :cut_off

  def calculate_offset(offset = 60)
    offset > duration.in_minutes ? duration : Biz::Duration.minutes(offset)
  end

  def calculate_terminus(is_promo)
    advance_by = is_promo ? 3 : 14
    advance_by -= 1 if options[:same_day] && !after_hours?
    origin.advance(days: advance_by)
  end

  # rubocop:disable Style/FormatString
  def calculate_origin(origin)
    return origin unless options[:cut_off]

    cut_off = Time.zone.parse('%<date>s %<time>s' % { date: origin.to_date, time: options[:cut_off] })

    origin > cut_off ? origin.end_of_day.advance(minutes: 1) : origin
  end
  # rubocop:enable Style/FormatString

  def same_day?(slot)
    in_zone(slot.start_time).to_date == origin.to_date
  end

  def after_hours?
    first_window = schedule.periods.between(origin, origin.advance(weeks: 1)).first
    first_window && in_zone(first_window.start_time).to_date > origin.to_date
  end

  def as_window(slot)
    {
      start_time: in_zone(slot.start_time),
      end_time: in_zone(slot.end_time)
    }
  end

  def as_windows(date, slots)
    windows = slots.map { |slot| as_window(slot) }
    { date: date, opens_at: opening_time(date), closes_at: closing_time(date), windows: windows }
  end

  def hours(wday_symbol)
    schedule.send(:configuration).send(:raw).hours[wday_symbol.to_sym]&.first
  end

  def time_from_date_and_time(date, time)
    Time.use_zone(time_zone) { Time.zone.parse(time, date) }
  end

  def opening_time(date)
    hours = hours(date.strftime('%a').downcase)
    time_from_date_and_time(date, hours[0])
  end

  def closing_time(date)
    hours = hours(date.strftime('%a').downcase)
    time_from_date_and_time(date, hours[1])
  end

  def in_zone(time)
    return nil unless time

    time.in_time_zone(time_zone)
  end

  def slots
    Biz::DeliverySlots
      .new(schedule, origin, terminus, duration: duration, offset: offset)
      .reject { |slot| !options[:same_day] && same_day?(slot) }
  end
end
