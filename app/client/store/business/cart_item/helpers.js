// @flow
import _ from 'lodash';
import type { Supplier } from 'store/business/supplier';
import type { CartItem, CartShipment } from 'store/business/cart_item';
import { cart_item_helpers as store_business_helpers } from '@minibar/store-business/src/cart_item';
import { delivery_method_helpers } from 'store/business/delivery_method';

const { itemsSubtotal } = store_business_helpers;

// TODO: move to order helpers and scrape getAllShipments from cider: src/business/order/selectors
const getShipments = (
  cart_items: Array<CartItem>,
  suppliers: Array<Supplier>,
  selected_delivery_methods: {[string]: string}
) => {
  const grouped_items = store_business_helpers.groupItemsBySupplier(cart_items);
  const supplier_ids = Object.keys(grouped_items);

  const shipments = supplier_ids.map(supplier_id => {
    const supplier = _.find(suppliers, {id: parseInt(supplier_id)});
    if (!supplier) return null;
    const delivery_method = supplier.delivery_methods.find(dm => dm.id === selected_delivery_methods[supplier_id]);
    if (!delivery_method) return null;
    const items = grouped_items[supplier_id];

    return { supplier, delivery_method, items };
  });

  return _.compact(shipments);
};

const allMinimumsMet = (shipments: Array<CartShipment>) => (
  shipments.every(shipment => (
    !delivery_method_helpers.belowMinimum(shipment.delivery_method, itemsSubtotal(shipment.items))
  ))
);

const WEB_MAXIMUM_QUANTITY = 999;
const validateQuantity = (desired_quantity: number, in_stock: number) => (
  store_business_helpers.validateQuantity(desired_quantity, in_stock, WEB_MAXIMUM_QUANTITY)
);


export default {
  ...store_business_helpers,
  getShipments,
  allMinimumsMet,
  validateQuantity
};
