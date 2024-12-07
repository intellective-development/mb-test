import { combineReducers } from 'redux';

import { ShowAddToCartModal } from './product_browse.actions';

const addToCartModal = (
  state = {
    modalOpen: false,
    product_grouping: null,
    variant: null
  },
  action
) => {
  switch (action.type){
    case ShowAddToCartModal().type:
      return {
        ...state,
        ...action.payload
      };
    default:
      return state;
  }
};

const reducer = combineReducers({
  addToCartModal
});
export default reducer;

export * from './product_browse.actions';
export * from './product_browse.selectors';
// export * from './product_browse.procedures';
