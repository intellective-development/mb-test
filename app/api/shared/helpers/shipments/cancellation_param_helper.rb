# frozen_string_literal: true

module Shared
  module Helpers
    module Shipments
      # Shipments Cancellations param helper methods
      module CancellationParamHelper
        extend Grape::API::Helpers

        params :shipment_cancellation_params do
          requires :order_adjustment, type: Hash, allow_blank: false do
            requires :reason_id, type: Integer, allow_blank: false
            requires :description, type: String, allow_blank: false
            optional :cancellation_fee
          end
        end
      end
    end
  end
end
