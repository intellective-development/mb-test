module Businesses
  class Update
    attr_reader :business, :params

    def initialize(business, params)
      @business = business
      @params   = params
    end

    def call
      @success = business.update(params)

      self
    end

    def success?
      @success
    end
  end
end
