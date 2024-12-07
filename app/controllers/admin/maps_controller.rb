class Admin::MapsController < Admin::BaseController
  before_action :supplier_types

  def index
    zones = DeliveryZone.polygons
    zones = zones.active.supplier_shipping_active unless params[:inactive]
  end

  def suppliers
    cache_string = "admin/maps/supplier_pins/#{Supplier.active.count}"
    supplier_addresses = Rails.cache.fetch(cache_string, expires_in: 24.hours) do
      addresses = Address.supplier.map do |a|
        { lat: a.latitude, lng: a.longitude, supplier: a.addressable }
      end

      addresses.select! { |a| a[:lat] && a[:lng] && a[:supplier] }
      to_marker_geo_json(addresses.compact)
    end
    respond_to do |format|
      format.json { render json: supplier_addresses }
    end
  end

  def zones
    cache_string = "admin/maps/zones/#{DeliveryZone.active.count}"
    polygons = Rails.cache.fetch(cache_string, expires_in: 24.hours) do
      zones = DeliveryZonePolygon.includes(:shipping_method).active.all
      zones = zones.map do |dz|
        next unless dz.supplier.present? && dz.supplier.supplier_type.present?

        dz.to_geo.exterior_ring.points.map do |point|
          { lat: point.x, lng: point.y, supplier: { id: dz.supplier.id, name: dz.supplier.name, url: edit_admin_inventory_supplier_path(dz.supplier) } }
        end
      end
      to_polygon_geo_json(zones.compact)
    end

    respond_to do |format|
      format.json { render json: polygons }
    end
  end

  def orders
    all_orders = Rails.cache.fetch 'map-order-data', expires_in: 1.minute do
      orders = Order.includes(:ship_address, :user)
                    .where(created_at: Time.zone.today - 60.days..Time.zone.today - 30.days)
      orders = orders.map do |o|
        next unless o.ship_address&.try(:latitude) && o.ship_address&.try(:longitude)

        {
          lat: o.ship_address&.latitude,
          lng: o.ship_address&.longitude,
          user: o.user.name
        }
      end
      orders.uniq.compact
    end
    #    @orders = toMarkerGeoJSON(@orders)

    respond_to do |format|
      format.json { render json: to_marker_geo_json(all_orders) }
    end
  end

  private

  # use params, default to all
  def supplier_types
    @supplier_types = params[:zones] ? params[:zones][:supplier_type_id].compact.map(&:to_i) : SupplierType.all.pluck(:id)
  end

  def to_marker_geo_json(geoms)
    geoms.map! do |geom|
      supplier = geom[:supplier]
      geometry = {
        type: 'Point',
        coordinates: [geom[:lng], geom[:lat]]
      }
      properties = {
        'marker-size': 'medium',
        'marker-color': supplier_color(supplier)
      }
      properties[:supplier] = { id: supplier.id, name: supplier.name, url: edit_admin_inventory_supplier_path(supplier) } || {}
      { type: 'Feature', geometry: geometry, properties: properties }
    end
    geoms
  end

  def to_polygon_geo_json(geoms)
    geoms.map! do |geom|
      geom_coords = geom.map { |g| [g[:lng], g[:lat]] }
      geometry = {
        type: 'Polygon',
        coordinates: [geom_coords]
      }
      properties = {}
      properties[:supplier] = geom.first[:supplier] || []
      { type: 'Feature', geometry: geometry, properties: properties }
    end
    geoms
  end

  def supplier_color(supplier)
    return '#999999' unless supplier.active

    supplier_type_color(supplier.supplier_type.name)
  end

  def supplier_type_color(supplier_type)
    case supplier_type.downcase
    when 'wine & spirits'
      '#1087bf'
    when 'beer & mixers'
      '#f86767'
    else
      '#9c89cc'
    end
  end
end
