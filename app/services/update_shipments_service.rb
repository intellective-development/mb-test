require 'set'
class UpdateShipmentsService
  class OrderError < OrderCreationServices::OrderError; end

  # TODO: JM: Only here for debugging
  attr_accessor :order, :items_attributes, :variants, :supplier_items

  def initialize(order, items_attributes, retailers, **options)
    @order = order
    @items_attributes = items_attributes
    @retailers = retailers
    @options = options
    @skip_scheduling_check = options[:skip_scheduling_check]
  end

  def process
    add_variants_or_error
    set_gift_cards_attributes_or_error
    @supplier_items = items_by_supplier
    update_or_create_shipments
  end

  def update_or_create_shipments
    shipments_attributes.each do |shipment_attributes|
      next Shipment.find_by(id: shipment_attributes[:id])&.destroy if shipment_attributes.key?(:_destroy)

      shipment = @order.shipments.find_or_initialize_by(id: shipment_attributes[:id])
      order_items_attributes = shipment_attributes.delete(:order_items_attributes)
      shipment.assign_attributes(shipment_attributes)
      shipment.save!
      order_items_attributes.each do |order_item_attributes|
        order_item = shipment.order_items.find_or_initialize_by(id: order_item_attributes[:id])
        next @order.order_items.find(order_item_attributes[:id]).destroy if order_item_attributes.key?(:_destroy)

        order_item.assign_attributes(order_item_attributes)
        order_item.save!
      end

      next unless @options[:override_amounts]

      retailer = @retailers.select { |r| ([1] + r['minibarSupplierId']).include?(shipment.supplier_id) }.first
      next unless retailer

      order_item_ids = order_items_attributes.map { |oia| oia[:item_id] }
      fulfillment = retailer[:fulfillments].select { |f| f[:items].intersection(order_item_ids).any? }.first

      next unless fulfillment

      shipment.liquid = true if @order.liquid

      shipment.override_bag_fee(fulfillment[:details][:taxes][:bag].to_f / 100) if fulfillment[:details][:taxes][:bag].present?
      delivery_fee = (fulfillment[:delivery].to_f / 100 if fulfillment[:delivery].present?) || 0.0
      shipping_fee = (fulfillment[:shipping].to_f / 100 if fulfillment[:shipping].present?) || 0.0
      shipment.override_delivery_fee((delivery_fee.zero? ? shipping_fee : delivery_fee))
      shipment.override_tip_amount(fulfillment[:tip].to_f / 100) if fulfillment[:tip].present?
      shipping_tax = (fulfillment[:details][:taxes][:shipping].to_f / 100 if fulfillment[:details][:taxes][:shipping].present?) || 0.0
      delivery_tax = (fulfillment[:details][:taxes][:delivery].to_f / 100 if fulfillment[:details][:taxes][:delivery].present?) || 0.0
      shipment.set_shipping_tax((delivery_tax.zero? ? shipping_tax : delivery_tax).round(2))
      shipment.set_retail_delivery_fee((fulfillment[:details][:taxes][:retailDelivery].to_f / 100).round(2)) if fulfillment[:details][:taxes][:retailDelivery].present?

      shipment.save_shipment_amount
    end
  end

  def shipments_attributes
    @shipments_attributes ||= build_shipments_attributes
  end

  def build_shipments_attributes
    @supplier_items.flat_map do |supplier_id, attributes|
      supplier = find_supplier_or_error(supplier_id)
      all_order_items = attributes.values.flatten
      attributes.flat_map do |customer_placement, items_to_ship|
        attributes_for_shipment(supplier, items_to_ship, all_order_items, customer_placement)
      end
    end.concat(remove_shipments)
  end

  def attributes_for_shipment(supplier, items_to_ship, all_order_items, customer_placement)
    shipment = @order.shipments.find_by(supplier_id: supplier.id, customer_placement: customer_placement)

    shipment_attributes = build_shipment_attributes_or_error(shipment, supplier, items_to_ship, all_order_items)
    shipment_attributes[:order_items_attributes] = attributes_for_items(items_to_ship)
    shipment_attributes[:customer_placement] = customer_placement

    if shipment
      shipment_attributes[:id] = shipment.id
      shipment_attributes[:order_items_attributes].concat(remove_order_items(shipment, items_to_ship))
    else
      shipment_attributes[:supplier] = supplier
    end

    shipment_attributes
  end

  def build_shipment_attributes_or_error(shipment, supplier, items_to_ship, all_order_items)
    # TODO: Reconsider the supplier.default_shipping_method piece - since shipping method coverage
    # depends on address its not prudent to just pick the first (though this should not be an issue
    # for well behaved clients!)
    shipping_method = shipping_method_from_attributes[supplier.shipping_methods, items_to_ship] || shipment&.shipping_method || default_shipping_method(supplier)

    validate_shipping_method(shipping_method, all_order_items)

    scheduled_for = nil
    unless shipping_method&.shipped?
      scheduled_for = find_schedule(items_to_ship)
      validate_must_schedule(shipping_method, scheduled_for)
    end

    { shipping_method: shipping_method, scheduled_for: scheduled_for, order: @order }
  end

  def default_shipping_method(supplier)
    default_ship_method = supplier.default_shipping_method
    return default_ship_method if @order.ship_address.blank?
    return default_ship_method unless should_validate_address?(default_ship_method)
    return default_ship_method if default_ship_method.covers_address?(@order.ship_address)

    supplier.shipping_methods.find { |sm| sm.covers_address?(@order.ship_address) } || default_ship_method
  end

  def find_supplier_or_error(supplier_id)
    supplier = if @options[:override_amounts]
                 supplier_id && Supplier.braintree.find_by(id: supplier_id)
               else
                 supplier_id && Supplier.active.braintree.find_by(id: supplier_id)
               end
    supplier or raise OrderError.new('Invalid Supplier.', name: 'InvalidSupplier')
  end

  def find_schedule(items_attributes)
    items_attributes.find { |item| item[:scheduled_for] }&.fetch(:scheduled_for)
  end

  # TODO: Check if delivery_methods match an existing ShippingMethod
  #         => If ID is blank, allow to pass validation - when we create an order we'll assign a default
  #         => If ID is invalid then throw back a validation error.
  def shipping_method_from_attributes
    # Funky code: reduce_ids is the body for inject(Set.new)
    reduce_ids = ->(ids, item) { item[:delivery_method_id] ? ids.add(item[:delivery_method_id]) : ids }

    # returns a proc unique_ids(attributes) .curry[reduce_ids] supplies f
    unique_ids = ->(f, attributes) { attributes.inject(Set.new, &f).to_a }.curry[reduce_ids]

    # find the unique_ids returned by f[attributes] and takes the first one
    find_in_scope = ->(f, scope, attributes) { scope.where(id: f[attributes]).take }

    # return proc with partially applied unique_ids function
    find_in_scope.curry[unique_ids]
  end

  def attributes_for_items(items_attributes)
    items_attributes.map do |attributes|
      variant = attributes[:variant]
      item = @order.order_items.find_by(identifier: attributes[:identifier])
      item_attributes = attributes.slice(:identifier, :product_bundle_id, :variant, :quantity, :price, :bottle_deposits)
      item_attributes = item_attributes.merge(
        {
          id: item&.id,
          item_options: variant.read_options(attributes[:options]),
          tax_rate: lookup_tax_rate(variant)
        }
      )

      if @options[:override_amounts]
        item_attributes[:tax_charge] = attributes[:tax_charge]
        item_attributes[:item_id] = attributes[:item_id]
        item_attributes[:item_options] = attributes[:item_options] if attributes[:item_options].present?
      end

      item_attributes
    end
  end

  def lookup_tax_rate(variant)
    address = @order.shipping_methods.any?(&:pickup?) ? variant.supplier.address : @order.ship_address
    TaxRate.lookup(address&.zip_code, address&.probable_state_id, variant.product.tax_category_id)
  end

  def items_by_supplier
    @items_attributes.each_with_object({}) do |item, items_by_supplier|
      supplier_id = item[:variant].supplier_id
      customer_placement = item[:customer_placement] || 'standard'
      items_by_supplier[supplier_id] ||= {}
      items_by_supplier[supplier_id][customer_placement] ||= []
      items_by_supplier[supplier_id][customer_placement] << item
    end
  end

  def add_variants_or_error
    @items_attributes.map! do |item|
      item[:variant] = Variant.find_by(id: item[:variant_id] || item[:id])
      raise OrderError.new("Product #{item[:name]} is not valid.", name: 'InvalidItem') if item[:variant].nil?

      if @options[:skip_in_stock_check]
        validate_pre_sale_variant(item[:variant], item[:identifier], quantity: item[:quantity]) if @order.storefront.enable_pre_sale_placement
      else
        validate_variant(item[:variant], item[:identifier], quantity: item[:quantity])
      end

      item
    end
  end

  def set_gift_cards_attributes_or_error
    @items_attributes.map! do |item|
      if item[:variant].gift_card?
        raise OrderError.new("GiftCard '#{item[:variant].name}' requires options.", name: 'InvalidItem') unless item[:options]
        raise OrderError.new("GiftCard '#{item[:variant].name}' requires options[:price].", name: 'InvalidItem') if item[:variant].overridable? && !(item[:options][:price])

        item[:quantity] = item[:options][:recipients].count
      end
      item
    end
  end

  def remove_shipments
    tuples = @supplier_items.flat_map { |supplier_id, method| method.keys.map { |cp| [supplier_id, cp] } }
    query = @order.shipments
    tuples.each do |id, cp|
      cp_index = Shipment.customer_placements[cp]
      query = query.where.not('(supplier_id, customer_placement) in ((?))', [id, cp_index])
    end
    destroy_attributes_for query.pluck(:id)
  end

  def remove_order_items(shipment, attributes)
    query = shipment.order_items
    attributes.each do |attribute|
      query = query.where.not('variant_id = ? and identifier = ?', attribute[:variant_id], attribute[:identifier])
    end
    destroy_attributes_for(query.pluck(:id))
  end

  def destroy_attributes_for(ids)
    ids.map { |id| Hash[id: id, _destroy: '1'] }
  end

  def should_validate_address?(shipping_method)
    Feature[:validate_address_on_checkout].enabled? && !%w[pickup digital].include?(shipping_method.shipping_type)
  end

  def validate_shipping_method(shipping_method, all_order_items)
    raise OrderError.new('Invalid Delivery Method.', name: 'InvalidDeliveryMethod') unless shipping_method

    return if @options[:override_amounts]

    # Is Address in Covered By Supplier?
    raise OrderError.new("#{shipping_method.supplier.name} does not deliver to your address.", name: 'DeliveryUnavailable') if @order.ship_address && should_validate_address?(shipping_method) && !shipping_method.covers_address?(@order.ship_address)

    # Are required attributes for shipping method present?
    if @order.finalizing?
      ShippingMethod::ORDERING_REQUIREMENTS[shipping_method.shipping_type.to_sym].each do |attribute|
        raise OrderError.new("#{attribute} is required.", name: 'MissingShippingMethodDependency') if @order.attributes[attribute].nil?
      end
    end

    return unless @order.storefront&.enable_supplier_order_mins || @order.storefront&.enable_supplier_order_mins.nil?

    shipment_total = ->(items) { items.sum { |item| (item[:price] || item[:variant].price) * item[:quantity].to_f } }
    if shipment_total[all_order_items] < shipping_method.delivery_minimum
      raise OrderError.new(
        "Add more products to meet the order minimum of $#{shipping_method.delivery_minimum.to_i} for #{shipping_method.supplier_name}.",
        name: 'LowOrderSubTotal'
      )
    end
  end

  def validate_must_schedule(shipping_method, scheduled_for)
    # If the order is already scheduled, we let it proceed to the next check.
    return validate_scheduling(shipping_method, scheduled_for) if scheduled_for
    return if @skip_scheduling_check

    # Some store requires scheduling
    raise OrderError.new('Store only accepts scheduling.', name: 'InvalidDeliveryMethod') if shipping_method.requires_scheduling

    # Otherwise, the store must be always open (long distance shipping) or currently open (next-hour delivery).
    unless shipping_method.always_open? || shipping_method.open?
      # If the store is not open, we need to raise an error,
      if shipping_method.allows_scheduling
        # If the store allows scheduling, we kindly ask customers to do so.
        raise OrderError.new('Store is not currently open, please schedule.', name: 'InvalidDeliveryMethod')
      else
        # Otherwise, tell them when they can try again.
        raise OrderError.new("Store is not currently open, please try again at #{shipping_method.next_delivery}.", name: 'InvalidDeliveryMethod')
      end
    end

    # If we get here, the store must be open, so we let the order proceed.
    true
  end

  def validate_scheduling(shipping_method, scheduled_for)
    if !shipping_method.allows_scheduling
      raise OrderError.new('Delivery Method does not support scheduling.', name: 'InvalidDeliveryMethod')
    elsif scheduled_for < 3.hours.ago || scheduled_for > 15.days.since
      raise OrderError.new('Invalid scheduling window', name: 'InvalidDeliveryMethod')
    else
      true
    end
  end

  def validate_pre_sale_variant(variant, identifier, quantity:)
    exceeded = exceeded_product_order_limit(variant, quantity) ||
               exceeded_state_product_order_limit(variant, quantity) ||
               exceeded_supplier_product_order_limit(variant, quantity) ||
               exceeded_products_by_order(variant, identifier, quantity)

    raise_product_order_limit_error(variant) if exceeded
  end

  def validate_variant(variant, identifier, quantity:)
    raise OrderError.new("#{variant.product_name} is unavailable.", { name: 'InvalidItem' }, { itemId: variant.id }) if variant.inactive?
    raise OrderError.new("#{variant.product_name} is sold out.", { name: 'InvalidItem' }, { itemId: variant.id }) if variant.sold_out?
    raise OrderError.new("Only #{variant.quantity_available} of #{variant.product_name} available.", name: 'InvalidItem') if variant.quantity_available.to_i < quantity.to_i

    validate_pre_sale_variant(variant, identifier, quantity: quantity)
  end

  def raise_product_order_limit_error(variant)
    raise OrderError.new("#{variant.product_name} is unavailable for purchase.", { name: 'InvalidItem' }, { itemId: variant.id })
  end

  def exceeded_product_order_limit(variant, quantity)
    product_order_limit = ProductOrderLimit.active
                                           .find_by(product_id: variant.product_id)

    return false if product_order_limit.nil? || product_order_limit&.global_order_limit&.zero?

    product_order_limit.current_order_qty + quantity > product_order_limit.global_order_limit
  end

  def exceeded_state_product_order_limit(variant, quantity)
    state_product_order_limit = StateProductOrderLimit
                                .active
                                .where(product_order_limits: { product_id: variant.product_id })
                                .where(state_id: @order.ship_address&.state_id)
                                .first

    return false if state_product_order_limit.nil? || state_product_order_limit&.order_limit&.zero?

    state_product_order_limit.current_order_qty + quantity > state_product_order_limit.order_limit
  end

  def exceeded_supplier_product_order_limit(variant, quantity)
    supplier_product_order_limit = SupplierProductOrderLimit
                                   .active
                                   .joins(:supplier)
                                   .where(product_order_limits: { product_id: variant.product_id })
                                   .where(supplier_id: variant.supplier_id)
                                   .where(suppliers: { presale_eligible: true })
                                   .first

    return false if supplier_product_order_limit.nil? || supplier_product_order_limit&.order_limit&.zero?

    supplier_product_order_limit.current_order_qty + quantity > supplier_product_order_limit.order_limit
  end

  def exceeded_products_by_order(variant, identifier, quantity)
    LimitedProductOrder.limit_reached_in_order?(@order, variant.product, identifier, quantity)
  end

  # This should cleanup (remove) order items from the order/shipments
  def cleanup_order_items
    @order.shipments.each { |shipment| shipment.order_items.destroy_all }
    @order.shipments.destroy_all
  end
end
