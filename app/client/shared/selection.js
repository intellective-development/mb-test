// @flow

import { createSelector } from 'reselect';
import { groupBy, keys, map, some } from 'lodash';
import {useCallback } from 'react';
import { useSelector } from 'react-redux';

export const useReselector = (selector, ...args) => {
  if (args.length === 0){
    console.warn('No arguments supplied. Apply useSelector here instead.');
  }
  const memoizedSelector = useCallback(state => selector(state, ...args), [selector, args]);
  return useSelector(memoizedSelector);
};

const selectCartItems = createSelector(
  state => state.cart_item.all_ids, // use denormalize
  state => state.cart_item.by_id,
  (cartItemIds, cartItemsById) => map(cartItemIds, id => cartItemsById[id]),
);

const selectCurrentDeliveryMethodForSuppliers = createSelector(
  state => state.supplier.selected_delivery_methods,
  state => state.delivery_method.by_id,
  (state, supplierIds) => supplierIds,
  (selectedDeliveryMethods, deliveryMethods, supplierIds) => {
    const selectedDeliveryMethodIds = map(supplierIds, id => selectedDeliveryMethods[id]);
    return map(selectedDeliveryMethodIds, id => deliveryMethods[id]);
  }
);

export const hasCartShippingSuppliers = createSelector(
  selectCartItems,
  state => state.supplier.selected_delivery_methods,
  state => state.delivery_method.by_id,
  (cartItems, supplierSelectedDeliveryMethods, deliveryMethods) => {
    const supplierIds = keys(groupBy(cartItems, 'supplier_id'));
    const selectedDeliveryMethodsIds = map(supplierIds, id => supplierSelectedDeliveryMethods[id]);
    return some(map(selectedDeliveryMethodsIds, id => deliveryMethods[id]), { type: 'shipped' });
  },
);

export const hasShippingSuppliers = createSelector(
  selectCurrentDeliveryMethodForSuppliers,
  selectedDeliveryMethods => some(selectedDeliveryMethods, { type: 'shipped' })
);
