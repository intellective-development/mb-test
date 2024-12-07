# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidRefund
      class LiquidRefund < LiquidBase
        expose :id, as: :order_id
        expose :amount, format_with: :float_string
        expose :created_at, format_with: :timestamp
        expose :note
        expose :order_adjustments, with: BarOS::Entities::Orders::LiquidOrderAdjustment
        expose :refund_line_items, with: BarOS::Entities::Orders::LiquidOrderItem
        expose :restock
        expose :transactions

        private

        def refund_line_items
          object
            .shipments
            .flat_map(&:order_items)
            .group_by { |item| item.identifier&.to_i || item.variant_id }
            .to_a
        end

        def note
          object
            .order_charges
            .flat_map(&:description)
            .join(', ')
        end

        def order_transactions
          object
            .order_charges
            .flat_map(&:customer_refunds)
            .flat_map(&:transaction_id)
        end

        def shipment_transactions
          object
            .shipments
            .flat_map(&:shipment_charges)
            .flat_map(&:customer_refunds)
            .flat_map(&:transaction_id)
        end

        def transactions
          order_transactions + shipment_transactions
        end

        def restock
          false
        end

        def amount
          (order_charges + shipment_charges).to_f
        end

        def order_charges
          order_refunds.sum(&:amount).to_f
        end

        def order_refunds
          object
            .order_charges
            .flat_map(&:customer_refunds)
        end

        def shipment_charges
          shipment_refunds.sum(&:amount).to_f
        end

        def shipment_refunds
          object
            .shipments
            .flat_map(&:shipment_charges)
            .flat_map(&:customer_refunds)
        end
      end
    end
  end
end
