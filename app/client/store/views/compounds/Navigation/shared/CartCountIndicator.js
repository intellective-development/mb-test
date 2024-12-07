// @flow

import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { cart_item_selectors, cart_item_helpers } from 'store/business/cart_item';

import { MBText } from '../../../elements';
import styles from './CartCountIndicator.scss';

const cn = bindClassNames(styles);

type CartCountIndicatorProps = {|
  cart_item_count: number,
  className?: string
|};
const CartCountIndicator = ({cart_item_count, className}: CartCountIndicatorProps) => {
  // setting the count as the key forces react to re-render the object when the count changes,
  // ensuring the animation will run. Therefore, we always apply the `changed` class.
  // FIXME: find a more efficient way to handle this?

  return (
    <MBText.Span
      className={cn('cmNavCartCount', {cmNavCartCount__Hidden: cart_item_count === 0}, className)}
      key={cart_item_count}>
      {cart_item_count}
    </MBText.Span>
  );
};

// for now, we duplicate the cart item count in state and pull from that here whether we're inside or outside the store.
// eventually we'll be able to pull the whole cart in the parent and rely on that
const CartCountIndicatorSTP = () => {
  const findCartItems = Ent.find('cart_item');
  return (state) => ({
    cart_item_count: cart_item_helpers.itemListQuantity(findCartItems(state, cart_item_selectors.getAllCartItemIds(state)))
  });
};
const CartCountIndicatorContainer = connect(CartCountIndicatorSTP)(CartCountIndicator);

export default CartCountIndicatorContainer;

