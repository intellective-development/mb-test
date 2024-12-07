# frozen_string_literal: true

module Admin
  # PreSalesMethods
  #
  # Mixin for presale methods
  module PreSalesMethods
    def build_state_product_order_limits(params)
      params[:state_product_order_limit].to_h.map do |state_id, order_limit|
        StateProductOrderLimit.new(state_id: state_id, order_limit: order_limit)
      end
    end

    def build_supplier_product_order_limits(params)
      params[:supplier_product_order_limit].to_h.map do |supplier_id, order_limit|
        SupplierProductOrderLimit.new(supplier_id: supplier_id, order_limit: order_limit)
      end
    end

    def load_suppliers
      @suppliers = Supplier.active.where(presale_eligible: true)
    end

    def pre_sale_params
      params.require(:pre_sale).permit(:product_id, :name, :price, :starts_at, :merchant_sku,
                                       product_order_limit: [:global_order_limit],
                                       state_product_order_limit: {},
                                       supplier_product_order_limit: {})
    end
  end
end
