module Avalara
  class TaxService
    include SentryNotifiable

    REDIS_PREFIX = 'AvalaraTaxService'.freeze

    # To be considered:
    # - handle offline tax calculations
    # - support cancellation fees? OF020000 / restocking OR040000

    def initialize(shipment, fallback_address = nil)
      @client = Avalara::Client.get_avalara_client
      @shipment = shipment
      @fallback_address = fallback_address
    end

    def generate_transaction(checkout = true, override_tax = false)
      # Products
      transaction_lines = generate_transaction_lines(override_tax)

      order_amounts = Order::Amounts.new(@shipment.order)

      unless Feature[:split_avalara_transaction].enabled?
        # ServiceFee
        service_fee = order_amounts.service_fee_after_discounts
        transaction_lines.append(generate_service_fee_line(service_fee)) if service_fee.positive?
      end

      # Shipping fee
      transaction_lines.append(generate_shipping_fee_line(override_tax)) if @shipment.shipping_fee.positive?

      # Tip
      transaction_lines.append(generate_tip_line) if @shipment.tip_share.positive?

      # Discount
      transaction_lines.append(generate_discount_line) if @shipment.promo_amount.positive?

      # Shoprunner discount
      transaction_lines.append(generate_shoprunner_discount_line) if @shipment.shoprunner_amount.positive?

      # GiftCard
      transaction_lines.append(generate_gift_card_discount_line) if @shipment.gift_card_amount.positive?

      # Bag fee
      bag_fee_applicable = !(@shipment.bartender_shipment? || @shipment.digital?)
      transaction_lines.append(generate_bag_fee_line) if bag_fee_applicable

      # Retail delivery fee (State of Colorado)
      retail_delivery_fee_applicable = @shipment.retail_delivery_fee_shipment?
      transaction_lines.append(generate_retail_delivery_fee_line) if retail_delivery_fee_applicable

      root_transaction = {
        "lines": transaction_lines,
        "type": checkout ? 'SalesOrder' : 'SalesInvoice',
        "companyCode": company_code(@shipment.order),
        "date": @shipment.tax_time.strftime('%Y-%m-%d'),
        "customerCode": checkout ? 'CHECKOUT' : @shipment.user.id.to_s,
        "referenceCode": checkout ? 'CHECKOUT' : @shipment.order.number,
        "customerSupplierName": @shipment.supplier.display_name,
        "addresses": generate_transaction_addresses,
        "currencyCode": 'USD'
      }

      # Tax exemption code
      root_transaction['entityUseCode'] = @shipment.user.tax_exemption_code_value if @shipment.user.tax_exempt?

      root_transaction
    end

    def calculate_tax
      tax_identifier = Models::TaxIdentifier.new(@shipment, get_fallback_address)

      cached_calculation = get_cached_tax_calculation(tax_identifier)
      return cached_calculation unless cached_calculation.nil?

      transaction = generate_transaction
      create_avalara_transaction(tax_identifier, transaction)
    rescue StandardError => e
      message = "Could not calculate tax for shipment #{@shipment.id || 0}. Fallback will be used. Error: #{e}"
      notify_sentry_and_log(e, message, { tags: { shipment: @shipment.id || 0 } })

      tax_identifier ||= Models::TaxIdentifier.new(@shipment, get_fallback_address)
      Avalara::Fallback::Models::FallbackTaxCalculation.new(tax_identifier, @shipment, get_fallback_address)
    end

    def submit_invoice
      transaction = generate_transaction(false)
      create_avalara_transaction(Models::TaxIdentifier.new(@shipment), transaction)
    end

    def confirm_invoice(transaction_code)
      @client.commit_transaction(company_code(@shipment.order), transaction_code, { commit: true })
    end

    private

    def company_code(order)
      custom_code = order.storefront.business.avalara_company_code
      return custom_code if custom_code.present?

      ENV['AVALARA_COMPANY_CODE']
    end

    def generate_tip_line
      {
        "ref1": 'tip',
        "amount": @shipment.tip_share.to_f,
        "discounted": false,
        "description": 'Tip',
        "taxCode": 'NT'
      }
    end

    def generate_shipping_fee_line(override_tax = false)
      line = {
        "ref1": 'shipping',
        "amount": @shipment.shipping_fee.to_f,
        "discounted": false,
        "description": 'Shipping',
        "taxCode": 'FR030000' # TODO: confirm correct tax codes for shipping (pickup, 3rd party, common carriers)
      }

      if override_tax
        line['taxOverride'] = {
          "type": 'TaxAmount',
          "taxAmount": @shipment.shipping_tax.to_f.round(2),
          "reason": 'Precalculated'
        }
      end

      line
    end

    def generate_shoprunner_discount_line
      {
        "ref1": 'shoprunner',
        "amount": (@shipment.shoprunner_amount * -1).to_f,
        "discounted": false,
        "description": 'ShopRunner',
        "taxCode": 'NT'
      }
    end

    def generate_gift_card_discount_line
      {
        "ref1": 'giftcard',
        "amount": (@shipment.gift_card_amount_for_tax * -1).to_f,
        "discounted": false,
        "description": 'GiftCard',
        "taxCode": 'NT'
      }
    end

    def generate_discount_line
      {
        "ref1": 'discount',
        "amount": (@shipment.promo_amount * -1).to_f,
        "discounted": false,
        "description": 'Discount',
        "taxCode": 'NT'
      }
    end

    def generate_bag_fee_line
      address = @shipment.address || get_fallback_address
      Avalara::TaxServices::BagFeeLineService.call(address, @shipment)
    end

    def generate_retail_delivery_fee_line
      {
        "ref1": 'retaildeliveryfee',
        "amount": 0.0,
        "discounted": false,
        "description": 'Colorado Retail Delivery Fee',
        "taxCode": 'OF400000'
      }
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

    def generate_transaction_lines(override_tax = false)
      transaction_lines = []
      @shipment.order_items.each do |oi|
        line_item = {
          "ref1": oi.variant_id,
          "quantity": oi.quantity.to_i,
          "amount": (oi.quantity.to_f * oi.price.to_f).round_at(2),
          "discounted": false,
          "description": oi.variant.product_display_name
        }

        item_properties = Avalara::Helpers.get_variant_properties(oi.variant)
        line_item['parameters'] = item_properties unless item_properties.empty?

        tax_code = Avalara::Helpers.get_variant_tax_code(oi.variant)
        line_item['taxCode'] = tax_code if tax_code

        if override_tax
          line_item['taxOverride'] = {
            "type": 'TaxAmount',
            "taxAmount": oi.tax_charge.to_f.round(2),
            "reason": 'Precalculated'
          }
        end

        transaction_lines.append(line_item)
      end

      transaction_lines
    end

    def get_fallback_address
      return @fallback_address unless @fallback_address.nil?

      @shipment&.user&.addresses&.order('created_at DESC')&.limit(1)&.first # recent user address
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

    def generate_transaction_addresses
      origin_address = @shipment.supplier_address
      origin_transaction_address = generate_transaction_address(origin_address)

      raise Avalara::Error::StandardError, 'Missing supplier address' if origin_address.nil?

      raise Avalara::Error::FatalError, 'System was unable to produce valid transaction address for supplier address' if origin_transaction_address.nil?

      fallback_address = get_fallback_address
      destination_address = @shipment.address
      destination_address = fallback_address if destination_address.nil? && !fallback_address.nil?
      destination_transaction_address = generate_transaction_address(destination_address)

      if @shipment.pickup? || destination_address.nil?
        return {
          "singleLocation": origin_transaction_address
        }
      end

      raise Avalara::Error::StandardError, 'Fallback address was provided to TaxService, but system was unable to produce valid transaction address' if !fallback_address.nil? && destination_transaction_address.nil?

      raise Avalara::Error::StandardError, 'System was unable to produce valid transaction address for shipping address' if destination_transaction_address.nil?

      {
        "shipFrom": origin_transaction_address,
        "shipTo": destination_transaction_address
      }
    rescue Avalara::Error::StandardError => e
      Rails.logger.error "[TaxService] @shipment #{@shipment&.id}: #{e.message}"

      {
        "singleLocation": origin_transaction_address
      }
    end

    def create_avalara_transaction(tax_identifier, transaction)

      if @shipment.liquid?
        response = @client.get_transaction_by_code('RESERVEBAR', @shipment)
      else
        response = @client.create_transaction(transaction)
      end

      Rails.logger.info("Avalara tax identifier: #{tax_identifier&.hash} #{transaction&.to_s} #{response&.to_s}")

      raise Avalara::Error::FatalError, response['error'] if response['error']

      Redis.current&.set(get_cache_key(tax_identifier), Marshal.dump(response).force_encoding('UTF-8'), ex: 300)

      Models::TaxCalculation.new(tax_identifier, response)
    end

    def get_cache_key(tax_identifier)
      "#{REDIS_PREFIX}:#{tax_identifier.hash}"
    end

    def get_cached_tax_calculation(tax_identifier)
      cached_response_raw = Redis.current&.get(get_cache_key(tax_identifier))

      unless cached_response_raw.nil?
        # rubocop:disable Security/MarshalLoad
        cached_response = Marshal.load(cached_response_raw)
        # rubocop:enable Security/MarshalLoad

        return Models::TaxCalculation.new(tax_identifier, cached_response)
      end

      nil
    end
  end
end
