module ShipCategories
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = ship_category.save

      self
    end

    def success?
      @success
    end

    def ship_category
      @ship_category ||= ShipCategory.new(params)
    end
  end
end
