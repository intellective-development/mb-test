// @flow

import { combineReducers } from 'redux';
import type { Action } from '@minibar/store-business/src/constants';


export const hasCheckedForSuppliersReducer = (state: boolean = false, action: Action) => {
  switch (action.type){
    case 'SESSION:NO_SUPPLIER_REFRESH':
    case 'SUPPLIER:REFRESH_SUPPLIERS__SUCCESS':
    case 'SUPPLIER:REFRESH_SUPPLIERS__ERROR':
      return true;
    default:
      return state;
  }
};

export type LocalState = {
  has_checked_for_suppliers: boolean
};
const sessionReducer = combineReducers({
  has_checked_for_suppliers: hasCheckedForSuppliersReducer
});

export default sessionReducer;
