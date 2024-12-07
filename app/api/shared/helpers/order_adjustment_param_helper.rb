# frozen_string_literal: true

module Shared
  module Helpers
    # OrderAdjustment param helper methods
    module OrderAdjustmentParamHelper
      extend Grape::API::Helpers

      params :order_adjustment_params do
        requires :order_adjustment, type: Hash, allow_blank: false do
          requires :reason_id, type: Integer, allow_blank: false
          requires :description, type: String, allow_blank: false
          requires :credit, type: Boolean, allow_blank: false
          requires :financial, type: Boolean, allow_blank: false
          requires :amount, type: Float, allow_blank: false
        end
      end
    end
  end
end
