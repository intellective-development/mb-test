module PreSales
  class Create
    include BarOS::Cache::PreSales

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        @success = create_all
        raise ActiveRecord::Rollback unless success?

        update_bar_os_pre_sale_cache_async
      end

      self
    end

    def success?
      @success
    end

    def pre_sale
      keys = %i[name price starts_at product_id merchant_sku]
      pre_sale_params = params.slice(*keys)

      @pre_sale ||= PreSale.new(pre_sale_params.merge({ product_order_limit: product_order_limit }))
    end

    private

    def create_all
      return false unless create_product_order_limit.success?
      return false unless save_state_product_order_limit.success?
      return false unless save_supplier_product_order_limit.success?

      pre_sale.save
    end

    def create_product_order_limit
      @create_product_order_limit ||= ProductOrderLimits::Create.new(build_product_order_limit).call
    end

    def build_product_order_limit
      params.delete(:product_order_limit).merge({ product_id: params[:product_id] })
    end

    def product_order_limit
      @product_order_limit ||= create_product_order_limit.product_order_limit
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
  end
end
