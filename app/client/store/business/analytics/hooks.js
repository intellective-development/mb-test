import { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { cart_item_selectors } from '../cart_item';
import { track } from './actions';
import { getCartItemData } from './helpers';

const trackScreen = ({ dispatch, name, cartItems = [] }) => {
  dispatch(track({
    action: `${name}`
  }));
  cartItems.forEach(({ product_grouping, variant, quantity }) =>
    dispatch(track({
      action: `${name}`,
      content_type: 'product',
      items: [getCartItemData(product_grouping, variant, quantity)]
    })));
};

/** dispatches on mount by default, if params defined, then dispatches every time params change */
export const useTrackScreenEffect = name => {
  const dispatch = useDispatch();
  const cartItems = useSelector(cart_item_selectors.getAllCartItems);
  useEffect(() => {
    trackScreen({ name, cartItems, dispatch });
  }, []);
};
