module Avalara
  module Models
    # This class is used to generate a tax identifier for a shipment.
    class TaxIdentifier
      require 'digest'
      attr_accessor :hash

      def initialize(shipment, fallback_address = nil)
        @hash = generate_identifier(shipment, fallback_address)
      end

      def ==(other)
        @hash == other.hash
      end

      private

      def generate_identifier(shipment, fallback_address)
        parts = []
        parts << generate_address_part(shipment.supplier_address)
        parts << generate_address_part(shipment.address) unless shipment.address.nil?
        parts << generate_address_part(fallback_address) if shipment.address.nil? && !fallback_address.nil?
        parts << generate_membership_part(shipment.order.membership_plan_record) unless shipment.order.membership_plan_record.nil?
        parts << generate_items_part(shipment.order_items)

        Digest::MD5.hexdigest(parts.join('-'))
      end

      def generate_address_part(address)
        parts = []
        address.slice(:address1, :address2, :city, :state_name, :zip_code).each do |_, v|
          parts << v || ''
        end
        parts.join(';')
      end

      def generate_items_part(items)
        parts = []
        items.each do |i|
          parts << i.id
          parts << i.quantity
          parts << i.price
        end
        parts.join(';')
      end

      def generate_membership_part(membership)
        parts = []
        id = membership.is_a?(Membership) ? membership.membership_plan_id : membership.id
        parts << id
        parts << membership.free_on_demand_fulfillment_threshold
        parts << membership.free_shipping_fulfillment_threshold
        parts.join(';')
      end
    end

    # This class is used to generate a tax identifier for a cart.
    class CartTaxIdentifier
      require 'digest'
      attr_accessor :hash

      def initialize(supplier_address, user_address, cart_items)
        @hash = generate_identifier(supplier_address, user_address, cart_items)
      end

      def ==(other)
        @hash == other.hash
      end

      private

      def generate_identifier(supplier_address, user_address, cart_items)
        parts = []
        parts << generate_address_part(supplier_address)
        parts << generate_address_part(user_address)
        parts << generate_items_part(cart_items)

        Digest::MD5.hexdigest(parts.join('-'))
      end

      def generate_address_part(address)
        parts = []
        address.slice(:address1, :address2, :city, :state_name, :zip_code).each do |_, v|
          parts << v || ''
        end
        parts.join(';')
      end

      def generate_items_part(items)
        parts = []
        items.each do |i|
          parts << i.id
          parts << i.quantity
        end
        parts.join(';')
      end
    end

    # This class is used to calculate taxes
    class TaxCalculation
      attr_accessor :response

      def initialize(identifier, response)
        @identifier = identifier
        @response = response
      end

      def valid?(shipment, fallback_address = nil)
        @identifier == TaxIdentifier.new(shipment, fallback_address)
      end

      def get_tax_for_item(order_item)
        line = get_line_calculation!(order_item.variant_id)
        get_tax_from_line(line)
      end

      def get_bottle_fee_for_item(order_item)
        line = get_line_calculation!(order_item.variant_id)
        get_bottle_fee_from_line(line)
      end

      def get_retail_delivery_fee
        line = get_line_calculation('retaildeliveryfee')
        return 0.0 if line.nil?

        ((get_amount_from_line(line) || 0.0) + (get_summary_tax_from_line(line) || 0.0)).round(2)
      end

      def get_bag_fee
        line = get_line_calculation('bagfee')
        return 0.0 if line.nil?

        ((get_amount_from_line(line) || 0.0) + (get_summary_tax_from_line(line) || 0.0)).round(2)
      end

      def get_shipping_tax
        line = get_line_calculation('shipping')
        return 0.0 if line.nil?

        get_summary_tax_from_line(line) || 0.0
      end

      def get_membership_tax
        line = get_line_calculation('membershiptax')
        return 0.0 if line.nil?

        get_summary_tax_from_line(line) || 0.0
      end

      def get_total
        (get_total_amount + get_total_tax_calculated).to_f.round(2)
      end

      # private

      def lines
        @response['lines'] || []
      end

      def get_line_calculation(line_reference)
        lines.find { |line| line['ref1'] == line_reference.to_s }
      end

      def get_line_calculation!(line_reference)
        line = get_line_calculation(line_reference)
        return line unless line.nil?

        raise StandardError, "Cannot fetch tax calculation for line with reference: #{line_reference}"
      end

      def get_summary_tax_from_line(line)
        tax = line['taxCalculated']
        return tax.to_f unless tax.nil?

        nil
      end

      def get_summary_tax_from_line!(line)
        tax = get_summary_tax_from_line(line)
        return tax unless tax.nil?

        raise StandardError, "Cannot fetch tax amount calculation for line with reference: #{line['ref1']}"
      end

      def get_amount_from_line(line)
        amount = line['lineAmount']
        return amount.to_f unless amount.nil?

        nil
      end

      def get_total_tax_calculated
        amount = @response['totalTaxCalculated']

        amount.to_f.round(2)
      end

      def get_total_amount
        amount = @response['totalAmount']

        amount.to_f.round(2)
      end

      def bottle_fee?(line_detail)
        line_detail['taxType'] == 'Bottle'
      end

      def get_tax_from_line(line)
        line_details = line['details'] || []
        applied_taxes = line_details.reject { |detail| bottle_fee?(detail) }
        applied_taxes.map { |tax| tax['taxCalculated'].to_f }.sum(0.0)
      end

      def get_bottle_fee_from_line(line)
        line_details = line['details'] || []
        applied_fees = line_details.select { |detail| bottle_fee?(detail) }
        applied_fees.map { |tax| tax['taxCalculated'].to_f }.sum(0.0)
      end

      def get_transaction_code
        @response['code']
      end
    end
  end
end
