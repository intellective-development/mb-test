# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderRefund
      class LiquidOrderRefund < LiquidBase
        expose :order_id do |refund|
          refund.charge.order.id
        end
        expose :amount, format_with: :float_string
        expose :order_adjustments, with: BarOS::Entities::Orders::LiquidOrderAdjustment do |refund|
          refund.charge.order.order_adjustments
        end
        expose :created_at, as: :processed_at, format_with: :timestamp
        expose :created_at, format_with: :timestamp
        expose :transaction, &:transaction_id
        expose :note do |refund|
          refund.charge.order.order_charges.map(&:description).join(', ')
        end
      end
    end
  end
end
