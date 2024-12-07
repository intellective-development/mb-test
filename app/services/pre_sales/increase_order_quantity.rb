module PreSales
  class IncreaseOrderQuantity
    include IncreaseOrderQuantityLog
    include BarOS::Cache::PreSales

    attr_reader :shipment

    def initialize(shipment)
      @shipment = shipment
    end

    def call
      order_items.each do |item|
        increment_product_order_limits(item)
        increment_state_product_order_limits(state_product_order_limits, item)
        increment_supplier_product_order_limit(supplier_product_order_limits, item)
        PreSale.expire_cache(item.variant.product_id)
      end
      update_bar_os_pre_sale_cache_async

      self
    end

    private

    def increment_product_order_limits(item)
      product_order_limit = ProductOrderLimit.active
                                             .where(product_id: item.variant.product_id)
                                             .first

      return if product_order_limit.nil?

      product_order_limit_log(product_order_limit, item)
      product_order_limit.increment!(:current_order_qty, item.quantity)
    end

    def increment_state_product_order_limits(state_product_order_limits, item)
      state_pol = state_product_order_limits.find { |spol| spol.product_order_limit.product_id == item.variant.product_id }

      return if state_pol.nil?

      state_product_order_limit_log(state_pol, item)
      state_pol.increment!(:current_order_qty, item.quantity)
    end

    def increment_supplier_product_order_limit(supplier_product_order_limits, item)
      supplier_pol = supplier_product_order_limits.find { |spol| spol.product_order_limit.product_id == item.variant.product_id }

      return if supplier_pol.nil?

      supplier_product_order_limit_log(supplier_pol, item)
      supplier_pol.increment!(:current_order_qty, item.quantity)
    end

    def supplier_product_order_limits
      @supplier_product_order_limits ||= SupplierProductOrderLimit.active
                                                                  .includes(product_order_limit: :pre_sales)
                                                                  .joins(:product_order_limit)
                                                                  .joins(:supplier)
                                                                  .where(supplier_id: shipment.supplier_id)
                                                                  .where(suppliers: { presale_eligible: true })
    end

    def state_product_order_limits
      @state_product_order_limits ||= StateProductOrderLimit.active
                                                            .includes(product_order_limit: :pre_sales)
                                                            .joins(:product_order_limit)
                                                            .where(state_id: shipment.address.state_id)
    end

    def order_items
      @order_items ||= shipment.order_items.includes(:variant).joins(:variant)
    end
  end
end
