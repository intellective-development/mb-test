module FulfillmentServices
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = fulfillment_service.save

      self
    end

    def fulfillment_service
      @fulfillment_service ||= FulfillmentService.new(default_attributes.merge(params))
    end

    def success?
      @success
    end

    private

    def default_attributes
      { status: 'active' }
    end
  end
end
