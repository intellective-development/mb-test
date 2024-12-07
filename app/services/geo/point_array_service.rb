module Geo
  class PointArrayService
    attr_reader :shipping_method, :scope, :delivery_zones

    def initialize(shipping_method, scope = :active)
      @shipping_method = shipping_method
      @scope = scope
      @delivery_zones = if shipping_method.present?
                          @scope == :active ? shipping_method.delivery_zones.active.polygons : shipping_method.delivery_zones.inactive.polygons
                        else
                          @scope == :active ? DeliveryZone.active.polygons : DeliveryZone.inactive.polygons
                        end
    end

    def generate
      delivery_zones.map do |delivery_zone|
        delivery_zone.to_geo.exterior_ring.points.map do |point|
          { lat: point.x, lng: point.y, id: delivery_zone.id, priority: delivery_zone.priority }
        end
      end
    end
  end
end
