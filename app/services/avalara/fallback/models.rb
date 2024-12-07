module Avalara
  module Fallback
    module Models
      class FallbackTaxCalculation < Avalara::Models::TaxCalculation
        def initialize(identifier, shipment, fallback_address)
          super(identifier, nil)
          @shipment = shipment
          @order = shipment.order
          @fallback_address = fallback_address
          @bottle_fee_service = Avalara::Fallback::BottleFeeService.new(shipment, fallback_address)
        end

        def get_tax_for_item(order_item)
          address = Avalara::Helpers.get_taxable_address(@shipment, @fallback_address)

          total = (order_item.quantity.to_f * order_item.price.to_f).round_at(2)
          tax_rate = TaxRate.lookup(address&.zip_code, address&.probable_state_id, order_item&.variant&.product&.tax_category_id)

          rate = tax_rate&.percentage
          rate ||= 8.875

          (total * (rate / 100)).to_f.round_at(2)
        end

        def get_bottle_fee_for_item(order_item)
          @bottle_fee_service.get_bottle_fee(order_item)
        end

        def get_bag_fee
          Avalara::BagFeeService.new(@shipment, @fallback_address).get_bag_fee
        end

        def get_retail_delivery_fee
          states = ['CO'] & [@order&.ship_address&.state&.abbreviation, @order&.ship_address&.state_name, @order&.promo_address&.fetch('state')]
          return 0.0 unless states.any?

          0.27
        end

        def get_shipping_tax
          address = Avalara::Helpers.get_taxable_address(@shipment, @fallback_address)

          total = @shipment.shipping_fee
          shipping_tax_category = TaxCategory.find_by(name: 'Shipping')
          tax_rate = TaxRate.lookup(address&.zip_code, address&.probable_state_id, shipping_tax_category&.id)

          rate = tax_rate&.percentage
          rate ||= 8.875

          (total * (rate / 100)).to_f.round_at(2)
        end
      end
    end
  end
end
