// @flow

import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';

export type AutocompleteResultType = 'category' | 'brand' | 'product';
export type AutocompleteResult = {
  id: string,
  type: AutocompleteResultType,
  name: string,
  permalink: string,
};

export type LocalState = {
  current_query: string,
  by_query: {
    [query: string]: AutocompleteResult[]
  }
}

const initial_state: LocalState = {
  current_query: '',
  by_query: {}
};

const autocompleteReducer = (state: LocalState = initial_state, action: ActionWeaklyTyped) => {
  switch (action.type){
    case 'AUTOCOMPLETE:UPDATE_CURRENT_QUERY':
      return {
        ...state,
        current_query: action.payload.query
      };
    case 'AUTOCOMPLETE:FETCH__SUCCESS':
      return {
        ...state,
        current_query: action.payload.query,
        by_query: {
          ...state.by_query,
          [action.payload.query]: action.payload.results
        }
      };
    case 'CART_ITEM:DELETE_CART':
    case 'ORDER:CLEAR_COMPLETE_ORDER':
    case 'SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__SUCCESS':
    case 'SUPPLIER:SWAP_CURRENT_SUPPLIER':
      return initial_state;
    case 'SUPPLIER:REFRESH_SUPPLIERS__SUCCESS':
      return action.meta.suppliers_changed ? initial_state : state;
    default:
      return state;
  }
};

export default autocompleteReducer;
