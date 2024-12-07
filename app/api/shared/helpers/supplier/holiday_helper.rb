# frozen_string_literal: true

module Shared
  module Helpers
    module Supplier
      # Supplier Holiday helper methods
      module HolidayHelper
        def permitted_supplier_holiday_params(params)
          clean_params(params[:holiday]).permit(:start_date, :end_date, :user_id, shipping_types: [])
        end
      end
    end
  end
end
