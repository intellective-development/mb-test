# frozen_string_literal: true

module Admin
  module Fulfillment
    module Orders
      module Shipments
        # Admin::Fulfillment::Orders::Shipments::OrderItemsController
        class OrderItemsController < Admin::Fulfillment::BaseController
          before_action :load_order, :load_shipment, :load_order_item, only: %i[remove_dialogue]

          def remove_dialogue
            if !Feature[:disable_oos_availability_check].enabled? && @order.storefront.enable_oos_availability_check
              begin
                product_grouping_id_with_prefix = "GROUPING-#{@order_item.product_grouping_id}"
                product_id_with_prefix = "PRODUCT-#{@order_item.product_id}"

                rsa_products = RSA::SelectService.call(@order.storefront_id, product_grouping_id_with_prefix, nil, @shipment.address, nil, product_id_with_prefix, include_other_retailers: true)
              rescue StandardError => e
                Rails.logger.error("An error occurred while calling RSA: #{e.message}")

                rsa_products = []
              end

              @new_eligible_suppliers_with_variants = rsa_products.filter_map do |p|
                next unless product_eligible?(p)

                ["#{p.supplier.name} - $#{p.price.to_f * @order_item.quantity}", p.variant_id.to_s]
              end.uniq.sort
            end

            render :remove_dialogue, layout: false
          end

          private

          def load_order
            @order = Order.find(params[:order_id])
          end

          def load_shipment
            @shipment = @order.shipments.find(params[:shipment_id])
          end

          def load_order_item
            @order_item = @shipment.order_items.find(params[:id])
          end

          def product_eligible?(product)
            product.shipping_method == @order_item.shipment.shipping_type.to_sym &&
              product.in_stock >= @order_item.quantity &&
              product.product_id == @order_item.product_id &&
              product.supplier.id != @shipment.supplier_id &&
              (!@shipment.engraving? || (@shipment.engraving? && product.type.to_sym == :engraving)) &&
              !Variant.find_by(id: product.variant_id)&.sold_out?
          end
        end
      end
    end
  end
end
