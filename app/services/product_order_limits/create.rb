module ProductOrderLimits
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = product_order_limit.save

      self
    end

    def success?
      @success
    end

    def product_order_limit
      @product_order_limit ||= ProductOrderLimit.new(params)
    end
  end
end
