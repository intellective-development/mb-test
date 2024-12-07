# frozen_string_literal: true

class Admin::Inventory::ShippingMethodsController < Admin::BaseController
  respond_to :json, :html, :js

  before_action :load_supplier, only: %i[update destroy update_states add_delivery_zone remove_delivery_zone toggle_priority_delivery_zone activate_delivery_zone render_shipping_methods]
  before_action :load_shipping_method, only: %i[update destroy polygons states update_states activate_delivery_zone add_delivery_zone remove_delivery_zone toggle_priority_delivery_zone zip_codes]
  before_action :load_delivery_zone, only: %i[activate_delivery_zone remove_delivery_zone toggle_priority_delivery_zone]

  def create
    @supplier = Supplier.find(params[:supplier_id])
    @supplier.update({ delivery_breaks_attributes: delivery_break_params })
    @shipping_method = ShippingMethod.create!(allowed_params)

    redirect_to edit_admin_inventory_supplier_path(@supplier), notice: 'Shipping Method Created'
  end

  def update
    @shipping_method.update(allowed_params)
    if @shipping_method.errors.any?
      flash[:alert] = "Failed to update shipping method #{@shipping_method.name}: #{@shipping_method.errors.full_messages.join(', ')}"
    else
      flash[:notice] = 'Successfully updated shipping method.'
    end

    @supplier.update({ delivery_breaks_attributes: delivery_break_params })
    render_shipping_methods
  end

  def destroy
    @shipping_method.update_column(:active, false)
    @shipping_method.destroy

    redirect_to edit_admin_inventory_supplier_path(@supplier), notice: 'Shipping Method Deleted'
  end

  def polygons
    render json: get_delivery_zone_polygons
  end

  def states
    render json: get_delivery_zone_states
  end

  def zip_codes
    zip_code = params[:zip_code]
    polygon_data = get_polygon_info(zip_code)
    return redirect_to edit_admin_inventory_supplier_path(@shipping_method.supplier), alert: 'Couldn\'t find zip code' if polygon_data.nil?

    polygon_params = {
      type: :zipcode_polygon,
      points: polygon_data.coordinates
    }
    polygons = Geo::GeometryBuilderService.new(polygon_params).build
    errors = []
    polygons.each do |polygon|
      dz = DeliveryZonePolygon.create(shipping_method: @shipping_method, value: polygon.to_s)
      errors << dz.errors.full_messages.join(', ') unless dz.save
    end
    if errors.empty?
      redirect_to edit_admin_inventory_supplier_path(@shipping_method.supplier), notice: 'Delivery Zone Created'
    else
      redirect_to edit_admin_inventory_supplier_path(@shipping_method.supplier), alert: "Couldn\'t Save Zone - #{errors.join(', ')}"
    end
  end

  def add_delivery_zone
    polygon = Geo::GeometryBuilderService.new(params).build
    raise 'No Polygon' if polygon.nil?

    dz = DeliveryZonePolygon.create(shipping_method: @shipping_method, value: polygon.to_s)

    if dz.save
      render_shipping_methods
    else
      raise "Couldn't Save Zone"
    end
  end

  def remove_delivery_zone
    @zone.destroy if @zone && @zone.shipping_method_id == @shipping_method.id
    render_shipping_methods if @zone.save
  end

  def activate_delivery_zone
    @zone.active = !@zone.active if @zone && @zone.shipping_method_id == @shipping_method.id
    render_shipping_methods if @zone.save
  end

  def toggle_priority_delivery_zone
    @zone.priority = !@zone.priority if @zone && @zone.shipping_method_id == @shipping_method.id
    render_shipping_methods if @zone.save
  end

  def update_states
    Geo::UpdateShippingStatesService.new(@shipping_method, params[:states]).call
    render_shipping_methods
  end

  def delivery_zone_covered_users
    total = 0
    if (zone = DeliveryZonePolygon.find_by_id(params[:delivery_zone_id]))
      zipcodes = zone.overlapped_zipcodes + zone.contained_zipcodes
      covered = Address.active
                       .shipping
                       .within_zipcodes(zipcodes)
                       .within_delivery_zone(zone.id)
      total = covered.count('distinct(addresses.addressable_id)')
    end
    render json: { users: total }
  end

  private

  def load_supplier
    @supplier = ShippingMethod.find(params[:id]).supplier
  end

  def load_shipping_method
    @shipping_method = ShippingMethod.includes([:delivery_zones]).find(params[:id])
  end

  def load_delivery_zone
    @zone = DeliveryZone.find(params[:zone])
  end

  def allowed_params
    params
      .dup
      .require(:shipping_method)
      .permit(
        :name, :active, :shipping_type, :allows_scheduling, :supplier_id, :scheduled_interval_size, :delivery_minimum, :delivery_threshold,
        :delivery_fee, :delivery_expectation, :maximum_delivery_expectation, :cut_off, :same_day_delivery, :allows_tipping, :requires_scheduling,
        :shipping_flat_fee,
        delivery_hours: %i[starts_at ends_at wday id],
        delivery_breaks_attributes: %i[date start_time end_time apply_to_all _destroy id]
      )
  end

  def get_polygon_info(zip_code)
    zip_code_data = ZipcodeGeom.where("zcta5ce20 = '#{zip_code}'")
                               .select('ST_AsText(ST_GeometryN(geom, generate_series(1, ST_NumGeometries(geom)))) as geom')
                               .limit(1)
    return if zip_code_data.nil? || zip_code_data.empty?

    zip_code_data = zip_code_data.first
    RGeo::Geographic.spherical_factory.parse_wkt(zip_code_data.geom.to_s)
  end

  def delivery_break_params
    params[:shipping_method]
      .permit(delivery_breaks_attributes: %i[date start_time end_time apply_to_all _destroy id])[:delivery_breaks_attributes]
      .to_h.map do |_, attributes|
      attributes.to_h.merge({ shipping_methods: @shipping_method })
    end
  end

  def delivery_zone_params
    params.require(:points)
  end

  def get_delivery_zone_states
    {
      states: Geo::StateCoverageService.new(@shipping_method).generate
    }
  end

  def get_delivery_zone_polygons
    {
      active: Geo::PointArrayService.new(@shipping_method).generate,
      inactive: Geo::PointArrayService.new(@shipping_method, :inactive).generate
    }
  end

  def render_shipping_methods
    render 'admin/inventory/suppliers/_render_shipping_method.js', layout: nil
  end
end
