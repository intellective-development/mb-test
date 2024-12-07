# frozen_string_literal: true

module Admin
  module Fulfillment
    module Orders
      module Shipments
        # Admin::Fulfillment::Orders::Shipments::SubstitutionsController
        class SubstitutionsController < Admin::Fulfillment::BaseController
          before_action :load_order, :load_shipment, :load_substitution, only: %i[switch_supplier_for_oos_product_dialogue switch_supplier_for_oos_product]

          def switch_supplier_for_oos_product_dialogue
            if !Feature[:disable_oos_availability_check].enabled? && @order.storefront.enable_oos_availability_check
              begin
                product_grouping_id_with_prefix = "GROUPING-#{original_order_item.product_grouping_id}"
                product_id_with_prefix = "PRODUCT-#{original_order_item.product_id}"

                rsa_products = RSA::SelectService.call(@order.storefront_id, product_grouping_id_with_prefix, nil, @shipment.address, nil, product_id_with_prefix, include_other_retailers: true)
              rescue StandardError => e
                Rails.logger.error("An error occurred while calling RSA: #{e.message}")

                rsa_products = []
              end

              @new_eligible_suppliers_with_variants = rsa_products.filter_map do |p|
                next unless product_eligible?(p)

                price = p.price.to_f * (original_order_item.quantity - substitute_order_item.quantity)

                ["#{p.supplier.name} - $#{price}", p.variant_id.to_s]
              end.uniq.sort
            end

            render :switch_supplier_for_oos_product_dialogue, layout: false
          end

          def switch_supplier_for_oos_product
            if !Feature[:disable_oos_availability_check].enabled? && @order.storefront.enable_oos_availability_check && params[:new_variant_id].present?
              if original_order_item.quantity > substitute_order_item.quantity
                order_item_candidate = { 'variant_id' => params[:new_variant_id], 'quantity' => original_order_item.quantity - substitute_order_item.quantity }

                result = SupplierSwitchingForOosProducts::CreateOrderService.call(old_shipment_uuid: @shipment.uuid, order_item_candidates: [order_item_candidate])

                raise SupplierSwitchingForOosProducts::Errors::OrderCreationError, result.error unless result.success?

                flash[:notice] = 'Supplier switching process started'
              else
                flash[:alert] = "Supplier cannot be switched because substitution's original quantity is not greater than the substitute's quantity"
              end
            else
              flash[:alert] = 'Supplier cannot be switched'
            end
          rescue SupplierSwitchingForOosProducts::Errors::OrderCreationError => e
            Rails.logger.error e

            flash[:alert] = "Unable to switch supplier. Here's the error: (#{e.message})"
          ensure
            redirect_to edit_admin_fulfillment_order_url(@order.number)
          end

          private

          def load_order
            @order = Order.find(params[:order_id])
          end

          def load_shipment
            @shipment = @order.shipments.find(params[:shipment_id])
          end

          def load_substitution
            @substitution = @shipment.substitutions.find(params[:id])
          end

          def original_order_item
            @original_order_item ||= @substitution.original
          end

          def substitute_order_item
            @substitute_order_item ||= @substitution.substitute
          end

          def product_eligible?(product)
            product.shipping_method == @shipment.shipping_type.to_sym &&
              product.supplier.id != @shipment.supplier_id &&
              product.in_stock >= original_order_item.quantity - substitute_order_item.quantity &&
              product.product_id == original_order_item.product_id &&
              (!@shipment.engraving? || (@shipment.engraving? && product.type.to_sym == :engraving)) &&
              !Variant.find_by(id: product.variant_id)&.sold_out?
          end
        end
      end
    end
  end
end
