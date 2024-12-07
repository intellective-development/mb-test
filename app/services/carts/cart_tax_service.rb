# frozen_string_literal: true

module Carts
  # Carts::CartTaxService
  #
  # Service that Create the new Cart Tax
  class CartTaxService
    include SentryNotifiable

    REDIS_PREFIX = 'AvalaraCartTaxService'

    def initialize(cart)
      @client = Avalara::Client.get_avalara_client
      @cart = cart
      @user = cart.user
      @cart_items = cart.cart_items.active
      @shipping_address = cart.address || @user.addresses.last
    end

    def call
      taxes = {
        total_tax_calculated: 0.0,
        shipping_tax: 0.0,
        on_demand_tax: 0.0,
        bag_fee: 0.0,
        bottle_fee: 0.0,
        retail_delivery_fee: 0.0
      }

      items_by_shipping_method = {}
      @cart_items.each do |cart_item|
        supplier = cart_item.variant.supplier
        shipping_method = supplier_shipping_method(supplier)
        items_by_shipping_method[shipping_method.id] ||= []
        items_by_shipping_method[shipping_method.id] << cart_item
      end

      items_by_shipping_method.each do |shipping_method_id, cart_items|
        shipping_method = ShippingMethod.find(shipping_method_id)
        supplier = shipping_method.supplier
        response = call_avatax(cart_items, supplier, shipping_method)
        taxes[:total_tax_calculated] += response.get_total_tax_calculated
        taxes[:shipping_tax] += response.get_shipping_tax if shipping_method.shipped?
        taxes[:on_demand_tax] += response.get_shipping_tax if shipping_method.on_demand?
        taxes[:bag_fee] += response.get_bag_fee
        taxes[:retail_delivery_fee] += response.get_retail_delivery_fee
        taxes[:bottle_fee] += cart_items.map { |item| response.get_bottle_fee_for_item(item) }.sum
      end

      taxes
    end

    private

    def supplier_shipping_method(supplier)
      shipping_method = supplier.default_shipping_method
      return shipping_method if @shipping_address.blank?
      return shipping_method if shipping_method&.covers_address?(@shipping_address)

      supplier.shipping_methods.find { |sm| sm.covers_address?(@shipping_address) } || shipping_method
    end

    def call_avatax(cart_items, supplier, shipping_method)
      tax_identifier = Avalara::Models::CartTaxIdentifier.new(supplier.address, @shipping_address, cart_items)

      cached_calculation = get_cached_tax_calculation(tax_identifier)
      return cached_calculation unless cached_calculation.nil?

      transaction = generate_transaction(cart_items, supplier, shipping_method)
      create_avalara_transaction(tax_identifier, transaction)
    rescue StandardError => e
      message = "Could not calculate tax for cart #{@cart.id || 0}. Error: #{e}"
      notify_sentry_and_log(e, message, { tags: { cart: @cart.id || 0 } })

      tax_identifier || Avalara::Models::CartTaxIdentifier.new(supplier.address, @shipping_address, cart_items)
    end

    def generate_transaction(cart_items, supplier, shipping_method)
      transaction_lines = generate_transaction_lines(cart_items)

      if !Feature[:split_avalara_transaction].enabled? && @cart.cart_amount
        # ServiceFee
        service_fee = @cart.cart_amount.service_fee
        transaction_lines.append(generate_service_fee_line(service_fee)) if service_fee.positive?
      end

      if @cart.cart_amount.present?
        fee = @cart.cart_amount.shipping_fee + @cart.cart_amount.on_demand_fee
        transaction_lines.append(generate_shipping_fee_line(fee)) if fee.positive?
      end

      bag_fee_applicable = !(bartender_shipment?(cart_items) || shipping_method.digital?)
      transaction_lines.append(generate_bag_fee_line(shipping_method)) if bag_fee_applicable

      root_transaction = {
        "lines": transaction_lines,
        "type": 'SalesOrder',
        "companyCode": company_code,
        "date": DateTime.now.strftime('%Y-%m-%d'),
        "customerCode": 'CHECKOUT',
        "referenceCode": 'CHECKOUT',
        "customerSupplierName": supplier.display_name,
        "addresses": generate_transaction_addresses(supplier, shipping_method),
        "currencyCode": 'USD'
      }

      # Tax exemption code
      root_transaction['entityUseCode'] = @user.tax_exemption_code_value if @user.tax_exempt?

      root_transaction
    end

    def generate_transaction_lines(cart_items)
      transaction_lines = []
      cart_items.each do |cart_item|
        line_item = {
          "ref1": cart_item.variant_id,
          "quantity": cart_item.quantity.to_i,
          "amount": (cart_item.quantity.to_f * cart_item.price.to_f).round_at(2),
          "discounted": false,
          "description": cart_item.variant.product_display_name
        }

        item_properties = Avalara::Helpers.get_variant_properties(cart_item.variant)
        line_item['parameters'] = item_properties unless item_properties.empty?

        tax_code = Avalara::Helpers.get_variant_tax_code(cart_item.variant)
        line_item['taxCode'] = tax_code if tax_code

        transaction_lines.append(line_item)
      end

      transaction_lines
    end

    def generate_shipping_fee_line(fee)
      {
        "ref1": 'shipping',
        "amount": fee.to_f,
        "discounted": false,
        "description": 'Shipping',
        "taxCode": 'FR030000' # TODO: confirm correct tax codes for shipping (pickup, 3rd party, common carriers)
      }
    end

    def generate_bag_fee_line(shipping_method)
      Avalara::TaxServices::BagFeeLineService.call(@shipping_address, shipping_method)
    end

    def generate_service_fee_line(amount)
      address = Supplier.minibar_fees&.address

      {
        "ref1": 'servicefee',
        "amount": amount.to_f,
        "discounted": false,
        "description": 'Service Fee',
        "taxCode": 'NT',
        "addresses": {
          "singleLocation": generate_transaction_address(address)
        }
      }
    end

    def generate_transaction_address(address)
      return nil if address.nil? || address.address1.nil? || address.city.nil? || address.state_name.nil? || address.zip_code.nil?

      {
        "line1": address.address1,
        "line2": address.address2&.slice(0, 100) || '',
        "city": address.city,
        "region": address.state_name,
        "country": 'US',
        "postalCode": address.zip_code
      }
    end

    def generate_transaction_addresses(supplier, shipping_method)
      origin_address = supplier.address
      origin_transaction_address = generate_transaction_address(origin_address)

      raise Avalara::Error::StandardError, 'Missing supplier address' if origin_address.nil?

      raise Avalara::Error::FatalError, 'System was unable to produce valid transaction address for supplier address' if origin_transaction_address.nil?

      destination_address = @shipping_address
      destination_transaction_address = generate_transaction_address(destination_address)

      if shipping_method.pickup? || destination_address.nil?
        return {
          "singleLocation": origin_transaction_address
        }
      end

      {
        "shipFrom": origin_transaction_address,
        "shipTo": destination_transaction_address
      }
    rescue Avalara::Error::StandardError => e
      Rails.logger.error "[CartTaxService] @cart #{@cart&.id}: #{e.message}"

      {
        "singleLocation": origin_transaction_address
      }
    end

    def company_code
      custom_code = @cart.storefront.business.avalara_company_code
      return custom_code if custom_code.present?

      ENV['AVALARA_COMPANY_CODE']
    end

    def bartender_shipment?(cart_items)
      cart_items.all? { |item| item&.variant&.hierarchy_category&.name&.to_s&.downcase == 'book a bartender' }
    end

    def create_avalara_transaction(tax_identifier, transaction)
      response = @client.create_transaction(transaction)

      Rails.logger.info("#{tax_identifier&.hash} #{transaction&.to_s} #{response&.to_s}")

      raise Avalara::Error::FatalError, response['error'] if response['error']

      Redis.current&.set(get_cache_key(tax_identifier), Marshal.dump(response).force_encoding('UTF-8'), ex: 300)

      Avalara::Models::TaxCalculation.new(tax_identifier, response)
    end

    def get_cache_key(tax_identifier)
      "#{REDIS_PREFIX}:#{tax_identifier.hash}"
    end

    def get_cached_tax_calculation(tax_identifier)
      cached_response_raw = Redis.current&.get(get_cache_key(tax_identifier))

      unless cached_response_raw.nil?
        cached_response = Marshal.load(cached_response_raw) # rubocop:disable Security/MarshalLoad

        return Avalara::Models::TaxCalculation.new(tax_identifier, cached_response)
      end

      nil
    end
  end
end
