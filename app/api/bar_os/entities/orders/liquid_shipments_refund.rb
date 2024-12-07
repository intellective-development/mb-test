# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidShipmentsRefund
      class LiquidShipmentsRefund < LiquidBase
        expose :order_id do |refund|
          refund.charge.order.id
        end

        expose :amount, format_with: :float_string
        expose :created_at, as: :processed_at, format_with: :timestamp
        expose :created_at, format_with: :timestamp
        expose :refund_line_items, with: BarOS::Entities::Orders::LiquidOrderItem do |refund|
          refund.charge.shipment.order_items.group_by { |item| item.identifier&.to_i || item.variant_id }.to_a
        end
        expose :transaction, &:transaction_id
        expose :note do |refund|
          refund.charge.shipment.shipment_charges.flat_map(&:description).join(', ')
        end
      end
    end
  end
end
