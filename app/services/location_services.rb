# This service encapsulates location functionality which is used to route customers to suppliers.
#
# Assumptions:
# => A suppliers delivery zone is defined by one of the DeliveryZone models
# => Suppliers may have multiple delivery zones
# => Delivery zones may overlap
# => By default a customer only has a single supplier for each supplier type
#     - This usually means a single store, but may vary in cases like NYC or when there
#       are promotional suppliers active
# => By default we route to the closest supplier but this may be overridden by preferences
#    stored on the address

class LocationServices
  DEFAULT_OPTIONS = {
    defer_load: false,
    dynamic_routing: false,
    must_contain_routable_type: true,
    include_digital_delivery: false, # Includes digital shipment methods. Note: Converts to array
    supplier_ids: [] # Allows for an optional array of ids - [1,2,..]
  }.freeze

  ADDRESS_PARAMS = %w[name address1 address2 company city id
                      state_name zip_code doorkeeper_application_id
                      latitude longitude override_longitude
                      override_longitude].freeze

  attr_reader :shipping_methods, :required_supplier_types, :options,
              :address, :delivery_zones, :required_supplier_types,
              :deferrable_supplier_types, :deferrable_present

  #-----------------------------------
  # Instance methods
  #-----------------------------------
  def initialize(address, **options)
    @options = DEFAULT_OPTIONS.merge(options)

    @address = address
    @address.geocode! unless @address.geocoded?
    return unless @address.geocodable?

    @delivery_zones     = DeliveryZone.active.containing(@address)
    @shipping_methods   = ShippingMethod.includes(:supplier).active
    @shipping_methods   = @shipping_methods.shipped if @options[:shipped_only]

    @shipping_methods = @shipping_methods.not_digital # We dont want digital to appear everywhere
    @shipping_methods = @shipping_methods.joins(:delivery_zones).merge(@delivery_zones)

    @required_supplier_types    = SupplierType.routable.pluck(:id) if @options[:must_contain_routable_type]
    @deferrable_supplier_types  = SupplierType.deferrable.pluck(:id)
    @deferrable_present         = false
    # In the context of suppliers we select eligible shipping methods.
    @shipping_methods = @shipping_methods.where(supplier_id: @options[:supplier_ids]) if @options[:supplier_ids].present?
    if @options[:include_digital_delivery]
      digital_shipment_methods = ShippingMethod.active.digital
      digital_shipment_methods = digital_shipment_methods.where(supplier_id: @options[:supplier_ids]) if @options[:supplier_ids].present?
      @shipping_methods += digital_shipment_methods
    end
  end

  def init_best_supplier
    @best_supplier ||= BestSupplierService.new(
      address: @address,
      dynamic_routing: options[:dynamic_routing],
      preferred_supplier_ids: options[:preferred_supplier_ids],
      product_grouping_ids: options[:product_grouping_ids],
      product_ids: options[:product_ids],
      shipping_methods: @shipping_methods
    )
  end

  def best_supplier(suppliers)
    init_best_supplier

    @best_supplier.best_supplier(suppliers)
  end

  # Finds suppliers whose delivery zone covers the provided address.
  def find_suppliers(storefront = nil)
    return [] if delivery_zones.nil?

    if options[:supplier_ids].present?
      eligible_suppliers = Supplier.active.where(id: shipping_methods.map(&:supplier_id))
      eligible_suppliers = eligible_suppliers.included_on_minibar_storefront if storefront&.default_storefront?

      return eligible_suppliers
    end

    eligible_suppliers = load_suppliers(storefront)
    @deferrable_present = eligible_suppliers.any?(&:deferrable?)

    eligible_suppliers = filter_deferred_suppliers(eligible_suppliers)

    # stop returning suppliers on holiday or with no shipping methods
    eligible_suppliers.reject { |s| s.shipping_methods.reject { |sm| s.on_break?(sm.id) }.empty? }
  end

  def filter_deferred_suppliers(suppliers)
    if options[:defer_load]
      suppliers.reject { |s| s.supplier_type.deferrable? }
    else
      suppliers
    end
  end

  def alternative_suppliers(storefront)
    shipping_methods.map do |shipping_method|
      next if shipping_method.shipped?

      supplier = shipping_method.supplier

      next if supplier.exclude_minibar_storefront && storefront&.default_storefront?

      if required_supplier_types
        supplier if required_supplier_types.include?(supplier.supplier_type_id) && !deferrable_supplier_types.include?(supplier.supplier_type_id) && !shipping_method.shipped?
      else
        !deferrable_supplier_types.include?(supplier.supplier_type_id) ? supplier : nil
      end
    end.compact.select(&:active)
  end

  private

  def load_suppliers(storefront)
    load_scope = Supplier.active
                         .includes(:address, :profile, :delivery_hours, :supplier_type, shipping_methods: [:delivery_zones])
                         .joins(:shipping_methods)

    load_scope = load_scope.included_on_minibar_storefront if storefront&.default_storefront?
    load_scope = load_scope.where(shipping_methods: { id: shipping_methods.map(&:id) })

    load_scope
      .order(:id)
      .select('DISTINCT ON (suppliers.id) suppliers.*') # We can't do a .distinct when we have JSON columns - need to convert to JSONB if we want to do that
  end
end
