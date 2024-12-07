# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderShipment
      class LiquidOrderShipment < LiquidBase
        expose :state
        expose :created_at, format_with: :timestamp
        expose :updated_at, format_with: :timestamp
        expose :number
        expose :supplier_address, as: :retailer_address, with: BarOS::Entities::Orders::LiquidSupplierAddress
        expose :address, as: :customer_address, with: BarOS::Entities::Orders::LiquidAddress
        expose :shipping_method, with: BarOS::Entities::Orders::LiquidShippingMethod
        expose :customer_placement
        # There are two objects new packages and tracking detail so we can sent just one link
        # expose :tracking_company do |shipment|
        #   shipment.tracking_detail&.carrier
        # end
        # expose :tracking_numbers do |shipment|
        #   shipment.tracking_detail&.reference
        # end
        # expose :tracking_number_url
        expose :order_items, with: BarOS::Entities::Orders::LiquidOrderItem do |shipment|
          shipment.order_items.group_by { |item| item.identifier&.to_i || item.variant_id }.to_a
        end
        expose :retailer_id do |shipment|
          shipment.supplier&.id
        end
        expose :shipment_amount, with: BarOS::Entities::Orders::LiquidShipmentAmount
        expose :tracking_detail, with: BarOS::Entities::Orders::LiquidOrderShipmentTrackingDetail
        expose :packages, with: BarOS::Entities::Orders::LiquidOrderShipmentPackage
      end
    end
  end
end
