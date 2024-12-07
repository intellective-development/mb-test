require 'biz'
module Biz
  module Periods
    class Between < After
      def initialize(schedule, origin, terminus)
        @terminus = terminus
        super(schedule, origin)
      end

      private

      def weeks
        Range.new(
          Week.since_epoch(schedule.in_zone.local(origin)),
          Week.since_epoch(schedule.in_zone.local(terminus))
        )
      end

      attr_reader :terminus
    end

    class Proxy
      def between(origin, terminus)
        Between.new(schedule, origin, terminus)
      end
    end
  end
end
