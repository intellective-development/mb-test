// @flow
import Rx from 'rxjs';
import * as Ent from '@minibar/store-business/src/utils/ent';
import * as supplier_epics from '@minibar/store-business/src/supplier/epics';
import { supplier_actions, supplier_selectors } from '../supplier';
import * as mb_cookie from '../utils/mb_cookie';
import { address_selectors } from '../address';
import { session_actions } from '../session';

const SUPPLIER_REFRESH_POLL_INTERVAL = 60 * 1000 * 2; // 2 Minutes
const SUPPLIER_COOKIE_ID = 'sid';
const ADDRESS_COOKIE_ID = 'address';
const RELOAD_PRODUCT_GROUPINGS = 'reload_product_groupings';

// we take a mixture of the persisted redux state and the stored supplier data, and use it to refresh those entities
const rehydrateSuppliers = (action$, store) => {
  const findAddress = Ent.find('address');
  const rehydrate_action$ = action$
    // emit once after we've rehydrated
    .filter(action => action.type === 'persist/REHYDRATE')
    .take(1)

    // grab the address and supplier ids. if either are missing, do nothing
    .map(() => {
      const state = store.getState();
      const address = findAddress(state, address_selectors.currentDeliveryAddressId(state));
      const supplier_ids = getStoredSuppliersIds();

      // if this runs before there is an address or supplier_ids, mark it as having been attempted
      if (!address || !supplier_ids) return session_actions.noSupplierRefresh();

      // Instead of simply re-requesting the current suppliers by id, we resubmit the address, marking the suppliers as preferred.
      // This allows the API to replace any suppliers that are no longer valid (ie. turned off, no longer cover the address, etc.)
      // without affecting any of the others.
      return supplier_actions.refreshSuppliers(supplier_ids, address);
    })
    .concat(reloadProductGroupings() ? [session_actions.reloadProductGroupings()] : [])

    // emit nothing if we have no action we want dispatched
    .filter(action => !!action);

  return rehydrate_action$;
};

// The supplier "heartbeat".
// The core of the action creator are similar to rehydrate suppliers, but rely entirely on state
const pollSuppliers = (_action$, store) => {
  const findAddress = Ent.find('address');

  const poll_refresh_action$ = Rx.Observable
    .interval(SUPPLIER_REFRESH_POLL_INTERVAL)
    .map(() => {
      const state = store.getState();
      const address = findAddress(state, address_selectors.currentDeliveryAddressId(state));
      const supplier_ids = supplier_selectors.currentSupplierIds(state, { ignore_lazy_loaded: true });

      if (!address || !supplier_ids) return null;

      return supplier_actions.refreshSuppliers(supplier_ids, address);
    })

    // emit nothing if we have no action we want dispatched
    .filter(action => !!action);

  return poll_refresh_action$;
};

const setAddressSupplierCookie = (action$, store) => {
  const findAddress = Ent.find('address');

  const set_cookie$ = action$
    .do(() => {
      const state = store.getState();

      const address_cookie_value = mb_cookie.get(ADDRESS_COOKIE_ID) || {};
      const current_address = findAddress(state, address_selectors.currentDeliveryAddressId(state));
      const address_changed = current_address && (address_cookie_value.local_id !== current_address.local_id);

      const supplier_cookie_value = mb_cookie.get(SUPPLIER_COOKIE_ID);
      const formatted_supplier_ids = supplier_selectors.currentSupplierIds(state, { ignore_lazy_loaded: true }).join(',');
      const suppliers_changed = formatted_supplier_ids && (formatted_supplier_ids !== supplier_cookie_value);

      if (address_changed || suppliers_changed){
        // we always update the address and supplier cookies in tandem, as they are tightly coupled
        mb_cookie.set(ADDRESS_COOKIE_ID, current_address, { expires: 7, path: '/' });
        mb_cookie.set(SUPPLIER_COOKIE_ID, formatted_supplier_ids, { expires: 7, path: '/' });
        mb_cookie.set(RELOAD_PRODUCT_GROUPINGS, true, { path: '/' });
      }
    })

    // not dispatching an action
    .filter(() => false);

  return set_cookie$;
};

const clearReloadProductGroupings = action$ =>
  action$
    // emit once after we've triggered SESSION:RELOAD_PRODUCT_GROUPINGS
    .filter(action => action.type === 'SESSION:RELOAD_PRODUCT_GROUPINGS')
    .take(1)
    .do(() => mb_cookie.set(RELOAD_PRODUCT_GROUPINGS, false, { path: '/' }))
    .filter(() => false);

export default {
  ...supplier_epics,
  rehydrateSuppliers,
  pollSuppliers,
  clearReloadProductGroupings,
  setAddressSupplierCookie
};

// helpers

const SUPPLIER_COOKIE_KEY = 'sid';
const getStoredSuppliersIds = () => {
  // we try to pull it off the cookie
  const cookie = mb_cookie.get(SUPPLIER_COOKIE_KEY);
  if (cookie){
    // since this is being stored as a joined string, we need to parse it on the other side
    return cookie.split(',').map(s_id => parseInt(s_id));
  } else {
    return null;
  }
};

const reloadProductGroupings = () => mb_cookie.get(RELOAD_PRODUCT_GROUPINGS);
