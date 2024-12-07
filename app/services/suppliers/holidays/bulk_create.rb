# frozen_string_literal: true

module Suppliers
  module Holidays
    # This class aims to encapsulate the logic for creating multiple Supplier Holidays.
    class BulkCreate
      attr_accessor :holidays, :error

      def initialize(params: {})
        raise ArgumentError.new, 'Start date and end date cannot be blank' if params[:start_date].blank? || params[:end_date].blank?

        @params = params.dup
        @holidays = []
      end

      def call
        create_holidays

        self
      end

      def success?
        @error.nil?
      end

      private

      def create_holidays
        Holiday.transaction do
          (Date.parse(@params[:start_date])..Date.parse(@params[:end_date])).each do |date|
            holiday = create_holiday(date)

            add_to_holidays(holiday)
          rescue ActiveRecord::RecordInvalid => e
            reset_holidays
            add_error(e)

            raise ActiveRecord::Rollback
          end
        end
      end

      def create_holiday(date)
        attrs = @params.merge(date: date.strftime(Holiday::DATE_FORMAT))

        Holiday.create!(attrs)
      end

      def add_to_holidays(holiday)
        @holidays << holiday
      end

      def reset_holidays
        @holidays = []
      end

      def add_error(error)
        @error = error.message
      end
    end
  end
end
