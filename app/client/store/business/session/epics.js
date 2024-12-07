// @flow

import type { Observable } from 'rxjs';
import _ from 'lodash';
import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';
import { supplier_selectors } from '../supplier';
import { cart_item_selectors, cart_item_actions } from '../cart_item';

const fetchCart = (action$: Observable<ActionWeaklyTyped>, store: Object) => {
  const fetch_cart_response_action$ = action$
    .map(_action => supplier_selectors.currentSupplierIds(store.getState()))
    .distinctUntilChanged((prev, next) => _.isEqual(prev, next))
    .map(supplier_ids => {
      if (_.isEmpty(supplier_ids)) return null;
      const cart_id = cart_item_selectors.getCartId(store.getState());
      return cart_id && cart_item_actions.fetchCart(cart_id);
    })
    .filter(action => !!action);

  return fetch_cart_response_action$;
};

export default {
  fetchCart
};
