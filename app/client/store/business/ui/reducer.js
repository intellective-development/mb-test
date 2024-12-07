// @flow

import _ from 'lodash';
import { combineReducers } from 'redux';
import type { Action } from '@minibar/store-business/src/constants';
import type { CartItem } from 'store/business/cart_item';

type CartShareDiffState = Array<CartItem>;
export const cartShareDiffReducer = (state: CartShareDiffState = [], action: Action) => {
  switch (action.type){
    case 'CART_SHARE:APPLY__SUCCESS':
      return _.isEmpty(action.payload.removed_share_items) ? state : action.payload.removed_share_items;
    case 'UI:DISMISS_CART_SHARE_DIFF':
      return []; // reset to empty
    default:
      return state;
  }
};

export const shouldShowHelpModal = (state: boolean = false, action: Action) => {
  switch (action.type){
    case 'UI:SHOW_HELP_MODAL':
      return true;
    case 'UI:HIDE_HELP_MODAL':
      return false;
    default:
      return state;
  }
};

export const shouldShowDeliveryInfoModal = (state: boolean = false, action: Action) => {
  switch (action.type){
    case 'UI:SHOW_DELIVERY_INFO_MODAL':
      return true;
    case 'UI:HIDE_DELIVERY_INFO_MODAL':
      return false;
    default:
      return state;
  }
};

export const deliveryInfoShownForSuppliers = (state: ?boolean = false, action: Action) => { // TODO: test
  switch (action.type){
    case 'SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__SUCCESS':
      return false;
    case 'SUPPLIER:REFRESH_SUPPLIERS__SUCCESS':
      return !action.meta.suppliers_changed;
    case 'UI:SHOW_DELIVERY_INFO_MODAL': // relevant when address was changed outside the modal
    case 'UI:HIDE_DELIVERY_INFO_MODAL': // relevant when address was changed within the modal
      return true;
    default:
      return state;
  }
};

export const addressEntryModalDestination = (state: ?string = null, action: Action) => { // TODO: test
  switch (action.type){
    case 'UI:SHOW_DELIVERY_INFO_MODAL':
      return action.payload.destination;
    case 'UI:HIDE_DELIVERY_INFO_MODAL':
      return null;
    default:
      return state;
  }
};


export const mapSupplierId = (state: ?number = null, action: Action) => {
  switch (action.type){
    case 'UI:SHOW_SUPPLIER_MAP_MODAL':
      return action.payload.supplier_id;
    case 'UI:HIDE_SUPPLIER_MAP_MODAL':
      return null;
    default:
      return state;
  }
};

export type LocalState = {
  cart_share_diff: CartShareDiffState,
  show_help_modal: boolean,
  show_delivery_info_modal: boolean,
  delivery_info_shown_for_suppliers: boolean,
  address_entry_modal_destination: ?string,
  map_supplier_id: ?number
};
const uiReducer = combineReducers({
  cart_share_diff: cartShareDiffReducer,
  show_help_modal: shouldShowHelpModal,
  show_delivery_info_modal: shouldShowDeliveryInfoModal,
  delivery_info_shown_for_suppliers: deliveryInfoShownForSuppliers,
  address_entry_modal_destination: addressEntryModalDestination,
  map_supplier_id: mapSupplierId
});

export default uiReducer;
