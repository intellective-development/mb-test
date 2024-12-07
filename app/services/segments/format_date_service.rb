class Segments::FormatDateService
  class << self
    def call(date)
      return if date.nil?

      date.strftime(Segments::SegmentService::DATE_FORMAT)
    end
  end
end
