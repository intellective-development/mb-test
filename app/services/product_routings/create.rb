module ProductRoutings
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = product_routing.save

      schedule_inactivate_worker if success?

      self
    end

    def product_routing
      @product_routing ||= ProductRouting.new(params)
    end

    def success?
      @success
    end

    def schedule_inactivate_worker
      ProductRouting::InactivateWorker.perform_at(product_routing.ends_at, product_routing.id)
    end
  end
end
