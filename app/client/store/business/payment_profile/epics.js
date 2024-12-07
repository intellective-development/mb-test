// @flow

import _ from 'lodash';
import * as api from '@minibar/store-business/src/networking/api';
import createActionsForRequest from '@minibar/store-business/src/utils/create_actions_for_request';

export const createProfile = (action$: Object) => {
  const create_profile_response_action$ = action$
    .filter(action => action.type === 'PAYMENT_PROFILE:CREATE_PROFILE')
    .switchMap(action => {
      const cart_supplier_ids = cartSupplierIds();
      const { address, payment_method_nonce } = action.payload || {};
      let payment_profile_params = { payment_method_nonce, address: { ...address, address2: '' }}; //TODO: WHY DO WE NEED TO SET address2: '' ???
      if (_.some(cart_supplier_ids)){ // api is expecting string comma separated number(s)
        payment_profile_params = { ...payment_profile_params, supplier_id: cart_supplier_ids.join(',') };
      }
      return createActionsForRequest(api.createPaymentProfile(payment_profile_params), action.type, action.meta);
    });

  return create_profile_response_action$;
};

// helpers

const cartSupplierIds = () => {
  if (!global.Store || !global.Store.Order) return [];
  const order_items = Store.Order.get('order_items'); // TODO: remove reference to global order object
  return _.uniq(order_items.map(item => item.supplier_id));
};

export default {
  createProfile
};
