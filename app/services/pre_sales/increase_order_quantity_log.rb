module PreSales
  module IncreaseOrderQuantityLog
    extend ActiveSupport::Concern

    def product_order_limit_log(product_order_limit, item)
      details = {
        presale_id: product_order_limit.pre_sales.first.id,
        product_order_limit_id: product_order_limit.id,
        current_order_qty: product_order_limit.current_order_qty,
        global_order_limit: product_order_limit.global_order_limit
      }.merge(item_attributes(item))

      Rails.logger.info("Incrementing pre_sale #{details}")
    end

    def state_product_order_limit_log(state_pol, item)
      details = {
        presale_id: state_pol.product_order_limit.pre_sales.first.id,
        state_product_order_limit_id: state_pol.id,
        state_id: state_pol.state_id,
        current_order_qty: state_pol.current_order_qty,
        order_limit: state_pol.order_limit
      }.merge(item_attributes(item))

      Rails.logger.info("Incrementing pre_sale on state #{details}")
    end

    def supplier_product_order_limit_log(supplier_pol, item)
      details = {
        presale_id: supplier_pol.product_order_limit.pre_sales.first.id,
        supplier_product_order_limit_id: supplier_pol.id,
        supplier_id: supplier_pol.supplier_id,
        current_order_qty: supplier_pol.current_order_qty,
        order_limit: supplier_pol.order_limit
      }.merge(item_attributes(item))

      Rails.logger.info("Incrementing pre_sale on state #{details}")
    end

    def item_attributes(item)
      {
        product_id: item.variant.product_id,
        quantity: item.quantity,
        shipment_id: item.shipment_id
      }
    end
  end
end
