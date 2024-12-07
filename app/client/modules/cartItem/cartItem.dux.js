import { compact, map, groupBy, mapValues, memoize } from 'lodash';
import { createSelector } from 'reselect';
import { cart_item_actions } from '@minibar/store-business/src/cart_item';
import { selectCurrentMethodBySupplierId, selectSelectedDeliveryMethods } from '../supplier/supplier.dux';
import { selectDeliveryMethodById } from '../deliveryMethod/deliveryMethod.dux';

export const removeCartItem = cart_item_actions.removeCartItem;
export const updateCartItemQuantity = cart_item_actions.updateCartItemQuantity;

const localState = ({ cart_item }) => cart_item;

export const groupCartItemsBySupplier = cartItems => groupBy(cartItems, 'supplier_id');

export const selectCartItemIds = state => localState(state).all_ids;
export const selectCartItemById = state => localState(state).by_id;
export const selectCartItems = createSelector(
  selectCartItemIds,
  selectCartItemById,
  (ids, cartItemById) => compact(map(ids, id => cartItemById[id]))
);

export const selectShipmentsGrouped = createSelector(
  selectCartItems,
  groupCartItemsBySupplier
);

export const selectShipments = createSelector(
  selectCartItems,
  selectSelectedDeliveryMethods,
  // () => ({}), // TODO: scheduling
  (cartItems, currentDeliveryMethods) => {
    const cartItemsBySupplier = groupCartItemsBySupplier(cartItems);
    return mapValues(cartItemsBySupplier, memoize((shipmentCartItems, supplierId) => {
      const delivery_method_id = currentDeliveryMethods[supplierId];
      const cart_items = map(shipmentCartItems, 'id');
      const supplier = parseInt(supplierId);
      // const scheduled_for = scheduling[delivery_method_id];
      return ({cart_items, supplier, delivery_method_id /*, scheduled_for*/ });
    }));
  }
);

export const selectOrderItemsFromCart = createSelector(
  selectCartItems,
  selectSelectedDeliveryMethods,
  // () => ({}), // TODO: scheduling
  (cartItems, currentDeliveryMethods) => {
    return map(cartItems, ({ id, quantity, supplier_id }) => {
      const delivery_method_id = currentDeliveryMethods[supplier_id];
      return ({ id, quantity, delivery_method_id });
    });
  }
);

export const selectOrderItemsFromCartComplete = createSelector(
  selectCartItems,
  selectCurrentMethodBySupplierId,
  selectDeliveryMethodById,
  () => ({}), // TODO: scheduling
  (cartItems, currentMethodBySupplierId, deliveryMethodById, scheduling) => {
    return map(cartItems, ({ id, quantity, supplier_id }) => {
      const delivery_method_id = currentMethodBySupplierId(supplier_id);
      const deliveryMethod = deliveryMethodById[delivery_method_id];
      const scheduled_for = scheduling[delivery_method_id];
      return ({ id, quantity, deliveryMethod, scheduled_for });
    });
  }
);
