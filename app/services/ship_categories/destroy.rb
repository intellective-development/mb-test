module ShipCategories
  class Destroy
    attr_reader :ship_category

    def initialize(ship_category)
      @ship_category = ship_category
    end

    def call
      @success = ship_category.destroy

      self
    end

    def success?
      @success || false
    end
  end
end
