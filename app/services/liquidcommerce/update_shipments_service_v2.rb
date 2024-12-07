# frozen_string_literal: true

##
# UpdateShipmentsServiceV2
#
# Service for processing and updating shipments with Liquid Commerce integration.
# Handles order item conversion, fee calculations, and shipment state management.
class UpdateShipmentsServiceV2
  class OrderError < StandardError
    attr_reader :status, :detail

    def initialize(message, options = {})
      @status = options.delete(:status) || 400
      @detail = options.merge(message: message)
      super(message)
    end
  end

  def initialize(order, items_attributes, retailers, liquidcommerce_identifiers, **options)
    @order = order
    @items_attributes = items_attributes
    @retailers = retailers
    @liquidcommerce_identifiers = liquidcommerce_identifiers
    @options = options
    @logger = Logger.new
  end

  def process
    @logger.info("Processing order", order_id: @order.id, retailer_count: @retailers.size)
    group_items_by_shipment
    create_or_update_shipments
  end

  private

  class Logger
    def info(message, data = {})
      Rails.logger.info("[LIQUID_COMMERCE] #{message} | #{data.to_json}")
    end

    def error(message, data = {})
      Rails.logger.error("[LIQUID_COMMERCE] #{message} | #{data.to_json}")
    end
  end

  def group_items_by_shipment
    @logger.info("Starting shipment grouping", order_id: @order.id)
    @shipments_data = []

    @retailers.each do |retailer|
      retailer[:fulfillments].each do |fulfillment|
        liquidcommerce_items = @liquidcommerce_identifiers.select { |item| fulfillment[:items].include?(item[:cart_item_id]) }
        shipment_items = @items_attributes.select { |item| liquidcommerce_items.map { |li| li[:identifier] }.include?(item[:identifier]) }

        @shipments_data << build_shipment_data(retailer, fulfillment, shipment_items, liquidcommerce_items)
      end
    end
  end

  def build_shipment_data(retailer, fulfillment, shipment_items, liquidcommerce_items)
    supplier = liquidcommerce_items.first[:supplier]

    # Calculate shipping amounts using the new calculator
    shipping_amounts = LiquidCommerceCoupons::ShipmentCalculator.new(@order, @shipment)
                                                                .calculate_shipping_amounts(fulfillment)

    {
      supplier_id: supplier.id,
      shipping_method_type: fulfillment[:type],
      scheduled_for: fulfillment[:scheduledFor],
      items: shipment_items,
      supplier: supplier,
      shipping_method_id: fulfillment[:methodId],
      fulfillment_fee: shipping_amounts[:total_fulfillment],
      fulfillment_fee_tax: shipping_amounts[:shipping_tax],
      amounts: fulfillment[:details],
      discounts: fulfillment[:discounts],
      shipping_fee: shipping_amounts[:original_shipping],
      delivery_fee: shipping_amounts[:original_delivery],
      retail_fee: fulfillment[:delivery].to_f / 100.0,
      tax: fulfillment[:tax].to_f / 100.0,
      fulfillment_id: fulfillment[:id],
      fulfillment: fulfillment,
      shipping_amounts: shipping_amounts # Store the full shipping amounts for use in other methods
    }
  end

  def create_or_update_shipments
    @shipments_data.each do |shipment_data|
      shipment = setup_liquid_shipment(shipment_data)
      process_order_items(shipment, shipment_data)
      save_shipment_with_amounts(shipment, shipment_data)
    end
    @logger.info("Processing liquidcommerce shipments completed")
  end

  def setup_liquid_shipment(data)
    shipment = @order.shipments.find_or_initialize_by(
      supplier_id: data[:supplier_id],
      customer_placement: 'standard'
    )
    shipment.assign_attributes(
      liquidcommerce: true,
      liquid: true,
      delivery_fee: data[:delivery_fee],
      shipping_method: find_shipping_method(data[:supplier], data[:shipping_method_id], data[:fulfillment]),
      scheduled_for: data[:scheduled_for]
    )

    shipment
  end

  def process_order_items(shipment, data)
    shipment.order_items = data[:items].map do |item_data|
      convert_item_to_order_item(shipment, item_data)
    end
  end

  def convert_item_to_order_item(shipment, item_data)
    numeric_id = LiquidCommerceIdConverter.to_numeric(item_data[:cartItemId])
    shipment.order_items.find_or_initialize_by(variant_id: item_data[:variant_id], identifier: numeric_id).tap do |order_item|

      order_item.assign_attributes(
        quantity: item_data[:quantity],
        price: item_data[:price],
        total: item_data[:total],
        tax_charge: item_data[:tax_charge],
        bottle_deposits: item_data[:bottle_deposits],
        item_options: item_data[:item_options]
      )
    end
  end

  def save_shipment_with_amounts(shipment, data)
    begin
      # Cache the values we need to preserve
      fulfillment = data[:fulfillment]

      attributes = LiquidCommerceShipments::ShipmentAttributes.new(
        @order,
        @shipment
      ).build_amount_attributes(fulfillment)

      # First save to ensure we have a record
      if shipment.shipment_amount.present?
        shipment.shipment_amount.update!(attributes)
      else
        shipment.build_shipment_amount(attributes)
        shipment.shipment_amount.save(validate: false)
      end

      # Then set liquidcommerce values AFTER the initial save
      shipment.sync_liquidcommerce_attributes!(fulfillment)

      shipment.set_delivery_fee
      # Final save without reload
      shipment.save(validate: false)

      Rails.logger.info("[LIQUID_COMMERCE] Saved shipment with values: subtotal=#{shipment.instance_variable_get('@liquidcommerce_subtotal')}")
    rescue => e
      Rails.logger.error("[LIQUID_COMMERCE] Failed to save shipment: #{e.message}")
      raise e
    end
  end

  # def build_amount_attributes(fulfillment)
  #   details = fulfillment[:details] || {}
  #   taxes = details[:taxes] || {}
  #   discounts = details[:discounts] || {}
  #
  #   # if isOnDemand?(fulfillment)
  #   #   accumulated_ship_delivery = (fulfillment[:shipping].to_i - discounts[:shipping].to_i).to_f / 100.0
  #   #   accumulated_ship_delivery_tax = (
  #   #     taxes[:delivery].to_i +
  #   #       taxes[:retailDelivery].to_i
  #   #   ).to_f / 100.0
  #   # else
  #   #   accumulated_ship_delivery = (fulfillment[:delivery].to_i - discounts[:delivery].to_i).to_f / 100.0
  #   #   accumulated_ship_delivery_tax = (
  #   #     taxes[:shipping].to_i +
  #   #       taxes[:retailDelivery].to_i
  #   #   ).to_f / 100.0
  #   # end
  #   #
  #   # tax_total = (fulfillment[:tax] || 0).to_f / 100.0
  #   # total = (fulfillment[:total] || 0).to_f / 100.0
  #   #
  #   # engraving_fee = (fulfillment[:engraving].to_i - discounts[:engraving].to_i).to_f / 100.0
  #
  #   # Fee calculations
  #   if isOnDemand?(fulfillment)
  #     accumulated_ship_delivery = fulfillment[:delivery]
  #     accumulated_ship_delivery_tax = (
  #       taxes[:delivery].to_i +
  #         taxes[:retailDelivery].to_i
  #     ).to_f / 100.0
  #   else
  #     accumulated_ship_delivery = fulfillment[:shipping]
  #     accumulated_ship_delivery_tax = (
  #       taxes[:shipping].to_i +
  #         taxes[:retailDelivery].to_i
  #     ).to_f / 100.0
  #   end
  #
  #   tax_total = (fulfillment[:tax] || 0).to_f / 100.0
  #
  #   all_discounts = (fulfillment[:discounts] || 0).to_f / 100.0
  #
  #   total_before_discounts = (fulfillment[:discounts].to_i + fulfillment[:total].to_i).to_f / 100.0
  #
  #   test = {
  #     sub_total: (fulfillment[:subtotal] || 0).to_f / 100.0,
  #     taxed_amount: tax_total,
  #     shipping_charges: accumulated_ship_delivery.to_f / 100.0,
  #     fulfillment_fee: accumulated_ship_delivery.to_f / 100.0,
  #     taxed_total: (fulfillment[:total] || 0).to_f / 100.0,
  #     order_items_total: (fulfillment[:subtotal] || 0).to_f / 100.0,
  #     order_items_tax: (taxes[:products] || 0).to_f / 100.0,
  #     shipping_tax: accumulated_ship_delivery_tax,
  #     bottle_deposits: (taxes[:bottleDeposits] || 0).to_f / 100.0,
  #     bag_fee: (taxes[:bag] || 0).to_f / 100.0,
  #     engraving_fee: (fulfillment[:engraving] || 0).to_f / 100.0,
  #     engraving_fee_discounts: (discounts[:engraving] || 0).to_f / 100.0,
  #     engraving_fee_after_discounts: ((fulfillment[:engraving].to_i - discounts[:engraving].to_i).to_f / 100.0),
  #     gift_card_amount: (fulfillment[:giftCards] || 0).to_f / 100.0,
  #     coupon_amount: all_discounts,
  #     tip_amount: (fulfillment[:tip] || 0).to_f / 100.0,
  #     retail_delivery_fee: (taxes[:retailDelivery] || 0).to_f / 100.0,
  #     deals_total: 0.0,
  #     discounts_total: all_discounts,
  #     total_before_discounts: 0.0,
  #     total_before_coupon_applied: total_before_discounts,
  #     shoprunner_total: 0.0,
  #     additional_tax_amount: 0.0,
  #     membership_discount: 0.0,
  #     membership_shipping_discount: 0.0,
  #     membership_delivery_discount: 0.0
  #   }
  #
  #   test
  # end

  def calculate_shipping_tax(details)
    (details[:taxes][:shipping] || 0 + details[:taxes][:delivery] || 0 + details[:taxes][:retailDelivery] || 0).to_f / 100
  end

  def find_shipping_method(supplier, shipping_method_id, fulfillment)
    @logger.info("Finding shipping method", {
      supplier_id: supplier.id,
      shipping_method_id: shipping_method_id,
      fulfillment_id: fulfillment[:id]
    })

    fulfillment_name = "#{fulfillment[:id]} #{fulfillment[:type]} - LiquidCommerce Services"

    shipping_method = supplier.shipping_methods.find_by(id: shipping_method_id) ||
      supplier.shipping_methods.find_by(name: fulfillment_name)

    unless shipping_method
      @logger.info("Creating new shipping method", {
        supplier_id: supplier.id,
        fulfillment_id: fulfillment[:id]
      })

      shipping_method = supplier.shipping_methods.create!(
        name: fulfillment_name,
        shipping_type: map_fulfillment_type_to_shipping_type(fulfillment[:type]),
        active: true,
        delivery_fee: calculate_delivery_fee(fulfillment),
        delivery_minimum: calculate_delivery_minimum(fulfillment),
        delivery_threshold: calculate_delivery_threshold(fulfillment),
        delivery_expectation: fulfillment[:expectation][:detail],
        maximum_delivery_expectation: parse_expectation_time(fulfillment[:expectation][:short]),
        shipping_flat_fee: false,
        allows_scheduling: false,
        scheduled_interval_size: 120,
        same_day_delivery: isOnDemand?(fulfillment),
        allows_tipping: isOnDemand?(fulfillment)
      )
      return shipping_method
    end

    update_shipping_method(shipping_method, fulfillment)
    shipping_method
  end

  def update_shipping_method(shipping_method, fulfillment)
    @logger.info("Updating shipping method", {
      shipping_method_id: shipping_method.id,
      fulfillment_type: fulfillment[:type]
    })

    case fulfillment[:type]
    when 'onDemand'
      update_on_demand_shipping(shipping_method, fulfillment[:fees])
    when 'shipping'
      update_standard_shipping(shipping_method, fulfillment[:fees])
    else
      raise OrderError.new("Unsupported fulfillment type: #{fulfillment[:type]}",
                           name: 'InvalidFulfillmentType')
    end

    if fulfillment[:expectation]
      shipping_method.delivery_expectation = fulfillment[:expectation][:detail]
      shipping_method.maximum_delivery_expectation = parse_expectation_time(fulfillment[:expectation][:short])
    end
  end

  def update_on_demand_shipping(shipping_method, fees)
    shipping_method.delivery_fee = (fees[:fee] || 0).to_f / 100
    shipping_method.delivery_minimum = (fees[:min] || 0).to_f / 100
    shipping_method.shipping_flat_fee = true
    shipping_method.delivery_threshold = fees[:free][:active] ? (fees[:free][:min] || 0).to_f / 100 : nil
  end

  def update_standard_shipping(shipping_method, fees)
    individual_fee_config = fees[:individual]
    shipping_method.delivery_fee = (individual_fee_config[:fee] || 0).to_f / 100
    shipping_method.delivery_minimum = (individual_fee_config[:min] || 0).to_f / 100
    shipping_method.shipping_flat_fee = true
    shipping_method.delivery_threshold = fees[:free][:active] ? (fees[:free][:min] || 0).to_f / 100 : nil
  end

  def map_fulfillment_type_to_shipping_type(fulfillment_type)
    case fulfillment_type
    when 'onDemand'
      0 # On Demand Delivery
    when 'shipping'
      2 # Standard Shipping
    else
      raise OrderError.new("Unsupported fulfillment type: #{fulfillment_type}",
                           name: 'InvalidFulfillmentType')
    end
  end

  def calculate_delivery_fee(fulfillment)
    fees = fulfillment[:fees]
    case fulfillment[:type]
    when 'onDemand'
      (fees[:fee] || 0).to_f / 100
    when 'shipping'
      (fees[:individual][:fee] || 0).to_f / 100
    else
      0
    end
  end

  def calculate_delivery_minimum(fulfillment)
    fees = fulfillment[:fees]
    case fulfillment[:type]
    when 'onDemand'
      (fees[:min] || 0).to_f / 100
    when 'shipping'
      (fees[:individual][:min] || 0).to_f / 100
    else
      0
    end
  end

  def calculate_delivery_threshold(fulfillment)
    fees = fulfillment[:fees]
    fees[:free][:active] ? (fees[:free][:min] || 0).to_f / 100 : nil
  end

  def parse_expectation_time(expectation_short)
    match = expectation_short.match(/(\d+)-?(\d+)?\s*(mins?|hours?|days?)/)
    return nil unless match

    max_time = (match[2] || match[1]).to_i
    case match[3]
    when /min/
      max_time / 60.0 # Convert minutes to hours
    when /hour/
      max_time
    when /day/
      max_time * 24 # Convert days to hours
    end
  end

  def isOnDemand?(fulfillment)
    fulfillment[:type] == 'onDemand'
  end
end
