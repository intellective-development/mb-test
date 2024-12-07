module Avalara
  class OrderTaxService < TaxService
    def initialize(order, fallback_address = nil)
      @client = Avalara::Client.get_avalara_client
      @order = order
      @fallback_address = fallback_address
      @supplier = order.storefront.business.fee_supplier
    end

    def generate_transaction(checkout: true)
      transaction_lines = []

      # ServiceFee
      service_fee = @order.amounts.service_fee_after_discounts
      transaction_lines.append(generate_service_fee_line(service_fee)) if service_fee.positive?

      # Membership
      if @order.membership_plan_id.present?
        membership_plan = @order.membership_plan
        transaction_lines.append(generate_membership_tax_line(membership_plan))

        discount_plan = @order.amounts.membership_coupon_discount
        transaction_lines.append(generate_membership_discount_line(discount_plan)) if discount_plan.nonzero?
      end

      # TODO: We'll send in next step
      # video_gift_fee = @order.order_amount.video_gift_fee
      # transaction_lines.append(generate_video_gift_fee_line(video_gift_fee)) if video_gift_fee > 0

      generate_root_transacion(checkout, transaction_lines)
    end

    def calculate_tax
      transaction = generate_transaction

      return if transaction[:lines].empty?

      tax_identifier = generate_tax_identifier
      create_avalara_transaction(tax_identifier, transaction)
    end

    def submit_invoice
      transaction = generate_transaction(checkout: false)
      tax_identifier = generate_tax_identifier
      create_avalara_transaction(tax_identifier, transaction)
    end

    def confirm_invoice(transaction_code)
      @client.commit_transaction(company_code(@order), transaction_code, { commit: true })
    end

    private

    # try to avoid call another transaction with same params
    def generate_tax_identifier
      parts = []
      parts << generate_transaction_address(@supplier.address) if @supplier.address
      parts << generate_transaction_address(@order.ship_address) if @order.ship_address

      service_fee = @order.amounts.service_fee_after_discounts
      parts << generate_service_fee_line(service_fee) if service_fee.positive?
      parts << generate_membership_tax_line(@order.membership_plan) if @order.membership_plan_id.present?

      Digest::MD5.hexdigest(parts.join('-'))
    end

    def generate_root_transacion(checkout, transaction_lines)
      {
        "lines": transaction_lines,
        "type": checkout ? 'SalesOrder' : 'SalesInvoice',
        "companyCode": company_code(@order),
        "date": @order.tax_time.strftime('%Y-%m-%d'),
        "customerCode": @order.user.id.to_s,
        "referenceCode": @order.number,
        "customerSupplierName": @supplier.display_name,
        "addresses": generate_transaction_addresses,
        "currencyCode": 'USD'
      }.merge(generate_tax_exempt_attribute)
    end

    def generate_transaction_addresses
      origin_transaction_address = generate_transaction_address(@supplier.address)
      destination_transaction_address =
        generate_transaction_address(@order.ship_address) || generate_transaction_address(get_fallback_address)

      raise Avalara::Error::StandardError, 'Missing supplier address' if origin_transaction_address.nil?

      return { "singleLocation": origin_transaction_address } if destination_transaction_address.nil?

      {
        "shipFrom": origin_transaction_address,
        "shipTo": destination_transaction_address
      }
    end

    def generate_tax_exempt_attribute
      @order.user.tax_exempt? ? { entityUseCode: @order.user.tax_exemption_code_value } : {}
    end

    def generate_service_fee_line(amount)
      {
        "ref1": 'servicefee',
        "amount": amount.to_f,
        "discounted": false,
        "description": 'Service Fee',
        "taxCode": 'NT'
      }
    end

    def generate_video_gift_fee_line(amount)
      {
        "ref1": 'videogiftfee',
        "amount": amount.to_f,
        "discounted": false,
        "description": 'Video Gift Fee',
        "taxCode": 'SG030000'
      }
    end

    def generate_membership_tax_line(membership_plan)
      {
        "ref1": 'membershiptax',
        "amount": membership_plan.price.to_f,
        "discounted": false,
        "description": 'Membership Tax',
        "taxCode": 'OD020000'
      }
    end

    def generate_membership_discount_line(amount)
      {
        "ref1": 'membershipdiscount',
        "amount": (amount * -1),
        "discounted": false,
        "description": 'Membership Discount',
        "taxCode": 'OD020000'
      }
    end
  end
end
