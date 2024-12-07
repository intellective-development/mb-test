const localState = state => state.product_browse;

export const selectAddToCartModal = state => localState(state).addToCartModal;
