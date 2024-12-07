module ShipCategories
  class Update
    attr_reader :ship_category, :params

    def initialize(ship_category, params)
      @ship_category = ship_category
      @params        = params
    end

    def call
      @success = ship_category.update(params)

      self
    end

    def success?
      @success
    end
  end
end
