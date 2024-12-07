require 'biz'
module Biz
  class DeliverySlots < SimpleDelegator
    def initialize(schedule, origin, terminus, duration: Biz::Duration.hours(2), offset: Biz::Duration.hour(1))
      @schedule = schedule
      @origin   = origin
      @duration = duration
      @offset   = offset
      @terminus = terminus

      super(delivery_slots)
    end

    private

    attr_reader :schedule, :origin, :duration, :offset, :terminus

    def periods
      true_origin ? schedule.periods.between(true_origin, terminus) : []
    end

    def true_origin
      @true_origin ||= begin
        period = schedule.periods.between(origin, terminus).first
        return if period.nil?

        if period.contains?(origin)
          preceeding_period = schedule.periods.before(origin).first
          advance = advance_for(preceeding_period.start_time.min, period.start_time.min)
          period.start_time.change(sec: 0) + advance.in_seconds
        else
          period.start_time
        end
      end
    end

    def advance_for(preceeding_mins, period_mins)
      if preceeding_mins > period_mins
        Biz::Duration.minutes(preceeding_mins - period_mins)
      else
        Biz::Duration.minutes(preceeding_mins - period_mins + 60)
      end
    end

    def delivery_slots
      Enumerator::Lazy.new(periods) do |yielder, period|
        offset_time = period.start_time

        loop do
          slot = Biz::TimeSegment.new(offset_time, offset_time + duration.in_seconds)
          raise StopIteration unless (period & slot).duration == duration
          raise StopIteration if schedule.in_zone.local(slot.end_time).to_date > schedule.in_zone.local(terminus).to_date

          yielder << slot

          offset_time += offset.in_seconds
        end
      end
    end
  end
end
