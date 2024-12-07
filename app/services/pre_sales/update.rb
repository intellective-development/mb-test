module PreSales
  class Update
    include BarOS::Cache::PreSales

    attr_reader :pre_sale, :params

    def initialize(pre_sale, params)
      @pre_sale = pre_sale
      @params   = params
    end

    def call
      ActiveRecord::Base.transaction do
        @success = update_all
        raise ActiveRecord::Rollback unless success?

        update_bar_os_pre_sale_cache_async
      end

      self
    end

    def success?
      @success
    end

    private

    def update_all
      return false unless update_product_order_limit.success?
      return false unless save_state_product_order_limit.success?
      return false unless save_supplier_product_order_limit.success?

      pre_sale.update(params)
    end

    def update_product_order_limit
      ProductOrderLimits::Update.new(product_order_limit, build_product_order_limit_params).call
    end

    def build_product_order_limit_params
      params.delete(:product_order_limit).merge({ product_id: params[:product_id] })
    end

    def save_state_product_order_limit
      @save_state_product_order_limit ||=
        StateProductOrderLimits::Save
        .new(product_order_limit, params.delete(:state_product_order_limit))
        .call
    end

    def save_supplier_product_order_limit
      @save_supplier_product_order_limit ||=
        SupplierProductOrderLimits::Save
        .new(product_order_limit, params.delete(:supplier_product_order_limit))
        .call
    end

    def product_order_limit
      @product_order_limit ||= pre_sale.product_order_limit
    end
  end
end
