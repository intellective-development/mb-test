// @flow

import _ from 'lodash';
import { combineReducers } from 'redux';
import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';
import type { ProductGrouping } from '../product_grouping';
import type { Variant } from '../variant';

type ProductGroupingIdsState = number[];
export const searchSwitchProductGroupingIdsReducer = (state: ProductGroupingIdsState = [], action: ActionWeaklyTyped) => {
  switch (action.type){
    case 'SEARCH_SWITCH:FETCH__SUCCESS':
      return action.payload.result.product_groupings;
    default:
      return state;
  }
};

type SearchSwitchSupplierIdState = ?number;
export const searchSwitchSupplierIdReducer = (state: SearchSwitchSupplierIdState = null, action: ActionWeaklyTyped) => {
  switch (action.type){
    case 'SEARCH_SWITCH:FETCH__SUCCESS':{
      const variants = Object.values(action.payload.entities.variant || {});
      return _.get(variants, '[0].supplier_id') || null;
    } default:
      return state;
  }
};

export type SearchSwitch = {
  product_grouping_ids: ProductGroupingIdsState,
  supplier_id: SearchSwitchSupplierIdState
};
export const searchSwitchReducer = combineReducers({
  product_grouping_ids: searchSwitchProductGroupingIdsReducer,
  supplier_id: searchSwitchSupplierIdReducer
});

type SearchSwitchById = {[id: number]: SearchSwitch};
export const searchSwitchByIdReducer = (state: SearchSwitchById = {}, action: ActionWeaklyTyped) => {
  switch (action.type){
    case 'SEARCH_SWITCH:FETCH':
    case 'SEARCH_SWITCH:FETCH__SUCCESS':{
      const search_switch_id = action.meta.product_list_id;
      return {
        ...state,
        [search_switch_id]: searchSwitchReducer(state[search_switch_id], action)
      };
    }
    case 'PRODUCT_LIST:REMOVE_FILTER':
      return _.omit(state, action.meta.product_list_id);
    default:
      return state;
  }
};

// We create separate product_grouping and variant reducers here to prevent the alternative groupings/variants
// from mingling with the general population of product_groupings and variants.
type ProductGroupingById = {[id: string]: ProductGrouping};
export const productGroupingByIdReducer = (state: ProductGroupingById = {}, action: ActionWeaklyTyped) => {
  switch (action.type){
    case 'SEARCH_SWITCH:FETCH__SUCCESS':
      return {
        ...state,
        ...action.payload.entities.product_grouping
      };
    default:
      return state;
  }
};

type VariantById = {[id: number]: Variant};
export const variantByIdReducer = (state: VariantById = {}, action: ActionWeaklyTyped) => {
  switch (action.type){
    case 'SEARCH_SWITCH:FETCH__SUCCESS':
      return {
        ...state,
        ...action.payload.entities.variant
      };
    default:
      return state;
  }
};

export type LocalState = {
  by_id: SearchSwitchById,
  product_grouping: {
    by_id: ProductGroupingById
  },
  variant: {
    by_id: VariantById
  }
};

export default combineReducers({
  by_id: searchSwitchByIdReducer,
  product_grouping: combineReducers({by_id: productGroupingByIdReducer}),
  variant: combineReducers({by_id: variantByIdReducer})
});
