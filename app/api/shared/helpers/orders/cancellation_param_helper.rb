# frozen_string_literal: true

module Shared
  module Helpers
    module Orders
      # Orders Cancellations param helper methods
      module CancellationParamHelper
        extend Grape::API::Helpers

        params :order_cancellation_params do
          requires :order_adjustment, type: Hash, allow_blank: false do
            requires :reason_id, type: Integer, allow_blank: false
            requires :description, type: String, allow_blank: false
            optional :cancellation_fee
          end

          optional :send_confirmation_email, type: Boolean
        end
      end
    end
  end
end
