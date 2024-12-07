module ProductOrderLimits
  class Update
    attr_reader :product_order_limit, :params

    def initialize(product_order_limit, params)
      @product_order_limit = product_order_limit
      @params              = params
    end

    def call
      @success = product_order_limit.update(params)

      self
    end

    def success?
      @success
    end
  end
end
