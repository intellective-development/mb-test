// @flow

import * as React from 'react';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { connect } from 'react-redux';
import _ from 'lodash';
import bindClassNames from 'shared/utils/bind_classnames';
import type { CartItem, CartShipment } from 'store/business/cart_item';
import { supplier_selectors } from 'store/business/supplier';
import { cart_item_helpers } from 'store/business/cart_item';

import { MBLink, MBText } from '../../../../elements';
import ItemList from './ItemList';
import CheckoutCTA from './CheckoutCTA';
import styles from './CartDropdown.scss';

const cn = bindClassNames(styles);

type CartDropdownProps = {cart_items: Array<CartItem>, is_hidden: boolean, shipments: Array<CartShipment>};
const CartDropdown = ({cart_items, is_hidden, shipments}: CartDropdownProps) => (
  <div className={cn('cmCartDropdown_Container', {invisible: is_hidden})}>
    {_.isEmpty(cart_items) ? <EmptyCartContents /> : <CartContents cart_items={cart_items} shipments={shipments} />}
  </div>
);

const EmptyCartContents = () => (
  <div>
    <MBText.H4 className={styles.cmCartDropdown__EmptyTitle}>Your cart is empty</MBText.H4>
    <MBText.P className={styles.cmCartDropdown__EmptyBody}>
      {'Let\'s make sure the same thing doesn\'t happen to your glass!'}
    </MBText.P>
  </div>
);

type CartContentsProps = {cart_items: Array<CartItem>, shipments: Array<CartShipment>};
const CartContents = ({cart_items, shipments}: CartContentsProps) => (
  <div>
    <MBLink.Text href="/store/cart" className={styles.cmCartDropdown_CartLink}>
      View Cart
    </MBLink.Text>
    <ItemList items={cart_items} />
    <CheckoutCTA items={cart_items} shipments={shipments} />
  </div>
);

const CartDropdownSTP = () => {
  const findSuppliers = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));

  return (state, {cart_items}) => {
    const suppliers = findSuppliers(state, supplier_selectors.currentSupplierIds(state));
    const selected_delivery_methods = supplier_selectors.selectedDeliveryMethods(state);
    return { shipments: cart_item_helpers.getShipments(cart_items, suppliers, selected_delivery_methods)};
  };
};
const CartDropdownContainer = connect(CartDropdownSTP)(CartDropdown);

export default CartDropdownContainer;
