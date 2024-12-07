// @flow

import _ from 'lodash';
import type { Supplier } from '../supplier';
import type { CartItem } from '../cart_item';
import { cart_item_helpers } from '../cart_item';

// temporary helpers, intended to be replaced by the shared business logic

const orderItemsBySupplier = (order: Object) => {
  return _.groupBy(order.order_items, item => item.supplier_id);
};

// TODO: consolidate with cart helper getShipments when Order -> redux
export const getOrderShipments = (
  order: Object,
  cart_items: Array<CartItem>,
  suppliers: Array<Supplier>,
  selected_delivery_methods: {[string]: string}
) => {
  // we consider the cart items to be our source of truth on the actual items to display
  // however, the order items are currently the only things holding a few relevant pieces of information,
  // so we still need to grab them.

  const shipments = cart_item_helpers.getShipments(cart_items, suppliers, selected_delivery_methods);
  const grouped_order_items = orderItemsBySupplier(order);
  return shipments.map(shipment => {
    const order_items = grouped_order_items[shipment.supplier.id];
    return {
      ...shipment,
      // these two attributes are stored on the order items, we pull them out to provide a more consistent interface
      // they're wrapped in a get to protect against scenarios when the order and cart updates are out of sync
      scheduled: _.get(order_items, '[0].scheduled'),
      scheduled_for: _.get(order_items, '[0].scheduled_for')
    };
  });
};
