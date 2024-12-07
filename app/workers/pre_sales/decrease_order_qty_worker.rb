# frozen_string_literal: true

module PreSales
  # Decreases the order quantity for pre-sale shipments.
  class DecreaseOrderQtyWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: true,
                    retry_count: 3,
                    queue: 'internal',
                    lock: :until_executed

    def perform_with_error_handling(shipment_id)
      ActiveRecord::Base.transaction do
        Shipment.find(shipment_id).tap do |shipment|
          supplier_product_order_limits = SupplierProductOrderLimit.includes(:product_order_limit)
                                                                   .joins(:supplier)
                                                                   .active
                                                                   .where(supplier: shipment.supplier)
                                                                   .where(suppliers: { presale_eligible: true })

          state_product_order_limits = StateProductOrderLimit.includes(:product_order_limit)
                                                             .active
                                                             .where(state_id: shipment.address.state_id)

          shipment.order_items.each do |item|
            product_order_limits_decrease_current_qty(item)
            state_product_order_limits_decrease_current_qty(state_product_order_limits, item)
            supplier_product_order_limit_decrease_current_qty(supplier_product_order_limits, item)
            PreSale.expire_cache(item.variant.product_id)
          end
        end
      end
    end

    private

    def product_order_limits_decrease_current_qty(item)
      product_order_limit = ProductOrderLimit.active
                                             .where(product_id: item.variant.product_id)
                                             .first

      return if product_order_limit.nil?

      current_qty = product_order_limit.current_order_qty
      calculated_qty = current_qty - item.quantity

      product_order_limit.update!(current_order_qty: [calculated_qty, 0].max)
    end

    def state_product_order_limits_decrease_current_qty(state_product_order_limits, item)
      state_pol = state_product_order_limits.find { |spol| spol.product_order_limit.product_id == item.variant.product_id }

      return if state_pol.nil?

      current_qty = state_pol.current_order_qty
      calculated_qty = current_qty - item.quantity

      state_pol.update!(current_order_qty: [calculated_qty, 0].max)
    end

    def supplier_product_order_limit_decrease_current_qty(supplier_product_order_limits, item)
      supplier_pol = supplier_product_order_limits.find { |spol| spol.product_order_limit.product_id == item.variant.product_id }

      return if supplier_pol.nil?

      current_qty = supplier_pol.current_order_qty
      calculated_qty = current_qty - item.quantity

      supplier_pol.update!(current_order_qty: [calculated_qty, 0].max)
    end
  end
end
