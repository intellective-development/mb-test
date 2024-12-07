# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrder
      class LiquidOrder < LiquidBase
        expose :id
        expose :number, as: :order_number
        expose :state
        expose :financial_status
        expose :order_items, with: BarOS::Entities::Orders::LiquidOrderItem do |order|
          order.order_items.group_by { |item| item.identifier&.to_i || item.variant_id }.to_a
        end

        expose :refund, with: BarOS::Entities::Orders::LiquidRefund do |order|
          refunds? ? order : nil
        end

        expose :order_refunds, with: BarOS::Entities::Orders::LiquidOrderRefund do |_order|
          order_refunds? ? order_refunds : nil
        end

        expose :shipments_refunds, with: BarOS::Entities::Orders::LiquidShipmentsRefund do |_order|
          shipments_refunds? ? shipments_refunds : nil
        end
        expose :discount_codes, with: BarOS::Entities::Orders::LiquidOrderDiscountCode do |order|
          order.coupons.map { |coupon| { code: coupon.code, amount: coupon.amount&.to_s, type: 'fixed_amount' } }
        end
        expose :amounts do
          expose :shipping_charges,    as: :shipping, format_with: :float_string
          expose :sales_tax,           as: :tax,                 format_with: :float_string
          expose :total_taxed_amount,  as: :tax_total,           format_with: :float_string
          with_options if: ->(instance, _options) { instance.shipping_methods.where(allows_tipping: true).exists? } do
            expose :tip_amount,          as: :tip,                 format_with: :float_string
            expose :tip_eligible_amount, as: :tip_eligible_amount, format_with: :float_string
          end
          expose :bottle_deposits,     as: :bottle_deposits,     format_with: :float_string
          expose :bag_fee,             as: :bag_fee,             format_with: :float_string
          expose :taxed_total,         as: :total,               format_with: :float_string
          expose :sub_total,           as: :subtotal,            format_with: :float_string
          expose :discounts_total,     as: :coupon,              format_with: :float_string
          expose :shipping_after_discounts,                      format_with: :float_string
          expose :service_fee,                                   format_with: :float_string
          expose :engraving_fee,                                 format_with: :float_string
          expose :delivery_charges do |_|
            delivery_charges&.transform_values do |v|
              v && Float(v).to_s
            end
          end
          expose :discounts do
            expose :deals_total,    as: :deals,    format_with: :float_string
            expose :coupon_amount,  as: :coupons,  format_with: :float_string
          end
          expose :without_digital_total_before_coupon_applied, as: :regular_products_revenue, format_with: :float_string
          expose :video_gift_fee, format_with: :float_string
          expose :current_charge_total,  format_with: :float_string
          expose :deferred_charge_total, format_with: :float_string
          expose :outstanding, format_with: :float_string
        end
        expose :coupons do |order|
          order.coupons.map { |coupon| "Discount: #{coupon.code}" }
        end
        expose :ship_address, with: BarOS::Entities::Orders::LiquidAddress
        expose :shipments,    with: BarOS::Entities::Orders::LiquidOrderShipment
        expose :bill_address, with: BarOS::Entities::Orders::LiquidAddress
        expose :customer,     with: BarOS::Entities::Orders::LiquidUser, &:user
        expose :email do |order|
          order.user.email
        end
        expose :note do |order|
          order.user.customer_service_comments.pluck(:note).join(', ')
        end
        expose :storefront_id
        expose :storefront_cart_id
        expose :storefront_uuid
        expose :storefront_account_id do |order|
          order.account&.storefront_account_id
        end
        expose :shipping_total do |order|
          order.shipments.map(&:total_amount).sum
        end
        expose :order_total do |order|
          order.amounts.taxed_total&.to_f
        end

        expose :gift_options, if: ->(instance, _options) { instance.gift? } do
          expose :gift_detail_message, as: :message
          expose :gift_detail_recipient_name, as: :recipient_name
          expose :gift_detail_recipient_phone, as: :recipient_phone
          expose :gift_detail_recipient_email, as: :recipient_email
        end

        expose :cancel_reasons, &:cancel_reporting_types

        expose :ip_address, as: :browser_ip
        expose :cancelled_at, format_with: :timestamp
        expose :cancelled_at, as: :closed_at, format_with: :timestamp
        expose :device_udid, as: :device_id
        expose :gateway
        expose :landing_site
        expose :landing_site, as: :landing_site_ref
        expose :payment_gateway_names
        expose :processed_at, format_with: :timestamp
        expose :source_identifier
        expose :platform, as: :source_name
        expose :status_url, as: :source_url
        expose :status_url, as: :order_status_url
        expose :metadata
        expose :created_at, format_with: :timestamp
        expose :updated_at, format_with: :timestamp
        expose :fulfillment_status do |order|
          order.fulfillment_status.to_s
        end
        expose :contact_email, &:email

        private

        delegate :recipient_name, :recipient_phone, :recipient_email, :message,
                 to: :gift_detail, prefix: true
        delegate :delivery_charges, to: :amounts, allow_nil: true
        delegate :gift_detail, :amounts, to: :object
        delegate :outstanding, to: :amounts, allow_nil: true

        def order_charges
          @order_charges ||= object.order_charges
        end

        def financial_status
          order_charges.map(&:charge).flat_map(&:charge_transitions).last&.to_state
        end

        def refunds?
          order_refunds? || shipments_refunds?
        end

        def order_refunds
          order_charges.flat_map(&:customer_refunds)
        end

        def order_refunds?
          order_refunds.any?
        end

        def shipments_refunds
          object
            .shipments
            .flat_map(&:shipment_charges)
            .flat_map(&:customer_refunds)
        end

        def shipments_refunds?
          shipments_refunds.any?
        end

        def gateway
          {
            'PAYPAL' => 'paypal',
            'APPLE_PAY' => 'apple_pay',
            'CREDIT_CARD' => 'braintree'
          }[object.payment_profile&.payment_type]
        end

        def landing_site
          object.storefront.home_url
        end

        def payment_gateway_names
          %w[BRAINTREE PAYPAL APPLE_PAY]
        end

        def processed_at
          # https://reservebar-tech.atlassian.net/browse/STO-802
          object.created_at
          # object
          #   .order_transitions
          #   .where('to_state IN (?)', %w[verifying placed])
          #   .order(created_at: :desc)
          #   .first
          #   &.created_at
        end

        # TODO: Missing field from MB
        def source_identifier
          ''
        end

        def sales_tax
          return unless object.amounts

          object.amounts.order_items_tax + object.amounts.shipping_tax
        end

        def tax_total
          return unless object.amounts

          object.amounts.taxed_amount + object.amounts.service_fee
        end

        def metadata
          return if object.metadata.is_a?(String) || object.metadata.is_a?(Array)

          object.metadata&.clone
        end
      end
    end
  end
end
