# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderItem
      class LiquidOrderItem < LiquidBase
        expose :product_id do |item|
          item[1].first.product_id
        end
        expose :product_bundle_id do |item|
          item[1].first.product_bundle_id
        end
        expose :variant_id do |item|
          item[1].first.variant_id
        end
        expose :price, format_with: :float do |item|
          item[1].first.price&.to_s
        end
        expose :tax_charge, format_with: :float do |item|
          item[1].sum(&:tax_charge)&.to_s
        end
        expose :total, format_with: :float do |item|
          item[1].sum(&:total)&.to_s
        end
        expose :sku do |item|
          item[1].first.variant&.sku
        end
        expose :quantity do |item|
          item[1].sum(&:quantity)
        end
        expose :name do |item|
          item[1].first.variant&.name
        end
        expose :supplier_name, as: :retailer_name do |item|
          item[1].first.supplier&.name
        end
        expose :supplier_id, as: :retailer_id do |item|
          item[1].first.supplier&.id
        end
        expose :carrier do |item|
          item[1].first.shipment.tracking_detail&.carrier
        end
        expose :discounts_total do |item|
          item[1].sum(&:discounts_total_value)&.to_s
        end
        expose :fulfillment_status do |item|
          'fulfilled' if %w[en_route delivered].include?(item[1].first.shipment.state)
        end
        expose :image_url do |item|
          item[1].first.variant&.featured_image
        end
        expose :scheduled_for do |item|
          timezone = item[1].first.supplier ? ActiveSupport::TimeZone::MAPPING.key(item[1].first.supplier.timezone) : 'Eastern Time (US & Canada)'
          item[1].first.shipment.scheduled_for&.in_time_zone(timezone)&.iso8601
        end
      end
    end
  end
end
