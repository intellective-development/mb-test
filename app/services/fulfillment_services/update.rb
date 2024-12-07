module FulfillmentServices
  class Update
    attr_reader :params, :fulfillment_service

    def initialize(fulfillment_service, params)
      @fulfillment_service = fulfillment_service
      @params              = params
    end

    def call
      @success = fulfillment_service.update(params)

      self
    end

    def success?
      @success
    end
  end
end
