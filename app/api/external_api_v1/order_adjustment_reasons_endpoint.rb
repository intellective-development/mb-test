# frozen_string_literal: true

class ExternalAPIV1
  # ExternalAPIV1::OrderAdjustmentReasonsEndpoint
  class OrderAdjustmentReasonsEndpoint < ExternalAPIV1
    resource :order_adjustment_reasons do
      desc 'Returns all adjustment reasons'
      get :adjustment do
        @order_adjustment_reasons = OrderAdjustmentReason.adjustment_reasons

        status 200
        present @order_adjustment_reasons, with: ExternalAPIV1::Entities::OrderAdjustmentReason
      end

      desc 'Returns all cancellation reasons'
      get :cancellation do
        @order_cancellation_reasons = OrderAdjustmentReason.cancellation_reasons

        status 200
        present @order_cancellation_reasons, with: ExternalAPIV1::Entities::OrderAdjustmentReason
      end
    end
  end
end
