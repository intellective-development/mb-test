module Geo
  class StateCoverageService
    attr_reader :shipping_method, :scope, :delivery_zones

    def initialize(shipping_method, scope = :active)
      @shipping_method = shipping_method
      @scope = scope
      @delivery_zones = @scope == :active ? shipping_method.delivery_zones.active.states : shipping_method.delivery_zones.inactive.states
    end

    def generate
      delivery_zones.map(&:value)
    end
  end
end
