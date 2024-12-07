# frozen_string_literal: true

module Avalara
  module TaxServices
    # Avalara::TaxServices::BagFeeLineService
    class BagFeeLineService < BaseService
      FEES = { CA: 0.10, OR: 0.05, DC: 0.05 }.freeze

      attr_reader :address, :shipment

      def initialize(address, shipment)
        super
        @address = address
        @shipment = shipment
      end

      def call
        {
          "ref1": 'bagfee',
          "amount": bag_fee_amount,
          "discounted": false,
          "description": 'Checkout bag',
          "taxCode": 'PB500100'
        }
      end

      private

      def bag_fee_amount
        return shipment.bag_fee.to_f.round(2) if use_seven_eleven_bag_fee?
        return 0.0 unless shipping_method.on_demand?

        FEES[address.state_abbr_name.to_sym] || 0.0
      end

      def shipping_method
        @shipping_method ||= shipment.shipping_method
      end

      def use_seven_eleven_bag_fee?
        Feature[:seven_eleven_bag_fee].enabled? && shipment.supplier.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN && shipment.bag_fee.present?
      end
    end
  end
end
