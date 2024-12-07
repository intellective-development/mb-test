// @flow

import * as React from 'react';
import formatCurrency from 'shared/utils/format_currency';
import type { CartItem, CartShipment } from 'store/business/cart_item';
import { cart_item_helpers } from 'store/business/cart_item';

import { MBButton, MBLink, MBText } from '../../../../elements';
import styles from './CartDropdown.scss';

type ButtonCTAProps = {items: Array<CartItem>, shipments: Array<CartShipment>};
const ButtonCTA = ({items, shipments}: ButtonCTAProps) => {
  return (
    <div className={styles.cmCartDropdown_CTAContainer}>
      <ItemSubtotal items={items} />
      <CheckoutButton shipments={shipments} />
    </div>
  );
};

type ItemSubtotalProps = {items: Array<CartItem>};
const ItemSubtotal = ({items}: ItemSubtotalProps) => (
  <div className={styles.cmCartDropdown_Subtotal} >
    <MBText.Span>Subtotal:</MBText.Span>
    <MBText.Span>{formatCurrency(cart_item_helpers.itemsSubtotal(items))}</MBText.Span>
  </div>
);

type CheckoutButtonProps = {shipments: Array<CartShipment>};
const CheckoutButton = ({shipments}: CheckoutButtonProps) => {
  const all_minimums_met = cart_item_helpers.allMinimumsMet(shipments);

  return (
    <MBLink.View href="/store/checkout" disabled={!all_minimums_met}>
      <MBButton size="medium" expand disabled={!all_minimums_met}>Proceed to Checkout</MBButton>
    </MBLink.View>
  );
};

export default ButtonCTA;
