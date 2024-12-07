// @flow

import { globalizeSelectors } from '@minibar/store-business/src/utils/globalizeSelectors';
import type { LocalState } from './reducer';

const LOCAL_PATH = 'ui';

// selectors
export const getCartShareDiff = (state: LocalState) => {
  return state.cart_share_diff;
};

export const isHelpModalShowing = (state: LocalState) => {
  return state.show_help_modal;
};
export const isDeliveryInfoModalShowing = (state: LocalState) => {
  return state.show_delivery_info_modal;
};
export const hasDeliveryInfoForSuppliersBeenShown = (state: LocalState) => {
  return state.delivery_info_shown_for_suppliers;
};
export const addressEntryModalDestination = (state: LocalState) => {
  return state.address_entry_modal_destination;
};

export const showSupplierMap = (state: LocalState) => !!state.map_supplier_id;
export const mapSupplierId = (state: LocalState) => state.map_supplier_id;

// global selectors
export default {
  ...globalizeSelectors(LOCAL_PATH, {
    getCartShareDiff,
    isHelpModalShowing,
    isDeliveryInfoModalShowing,
    hasDeliveryInfoForSuppliersBeenShown,
    addressEntryModalDestination,
    showSupplierMap,
    mapSupplierId
  })
};
