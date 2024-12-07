module ProductRoutings
  class Update
    attr_reader :params, :product_routing

    def initialize(product_routing, params)
      @product_routing = product_routing
      @params          = params
    end

    def call
      @success = product_routing.update(params)

      schedule_inactivate_worker if success? && product_routing.previous_changes.include?(:ends_at)

      self
    end

    def success?
      @success
    end

    private

    def schedule_inactivate_worker
      ProductRouting::InactivateWorker.perform_at(product_routing.ends_at, product_routing.id)
    end
  end
end
