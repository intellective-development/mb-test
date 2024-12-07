module Businesses
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = business.save

      self
    end

    def business
      @business ||= Business.new(params)
    end

    def success?
      @success
    end
  end
end
