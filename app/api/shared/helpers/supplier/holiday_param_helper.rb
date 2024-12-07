# frozen_string_literal: true

module Shared
  module Helpers
    module Supplier
      # Supplier Holiday param helper methods
      module HolidayParamHelper
        extend Grape::API::Helpers

        params :holiday_params do
          requires :holiday, type: Hash do
            requires :start_date, type: String, allow_blank: false
            requires :end_date, type: String, allow_blank: false
          end
        end
      end
    end
  end
end
