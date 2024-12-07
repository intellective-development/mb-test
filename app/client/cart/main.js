// @flow

import * as React from 'react';
import * as Ent from '@minibar/store-business/src/utils/ent';
import _ from 'lodash';
import { connect, useDispatch } from 'react-redux';
import pluralize from 'shared/utils/pluralize';
import formatCurrency from 'shared/utils/format_currency';
import type { CartItem, CartShipment } from 'store/business/cart_item';
import { cart_item_selectors, cart_item_helpers } from 'store/business/cart_item';
import { supplier_selectors } from 'store/business/supplier';
import { cart_share_selectors } from 'store/business/cart_share';
import { request_status_constants } from 'store/business/request_status';
import { ui_actions } from 'store/business/ui';

import FullPageLoader from 'shared/components/full_page_loader';
import CheckoutButton from 'cart/checkout_button';
import ShipmentPanel from 'cart/shipment_panel/main';
import OrderPanel from 'cart/order_panel';
import CartShareDiffWarning from 'cart/cart_share_diff_warning';
import CartContentLayout from 'cart/cart_content_layout';
import { hasShopRunnerToken } from 'shared/utils/shop_runner';
import { MBLink, MBLayout } from '../store/views/elements';
import { useTrackScreenEffect } from '../store/business/analytics/hooks';

const { LOADING_STATUS } = request_status_constants;

type CartProps = {
  cart_items: Array<CartItem>,
  shipments: Array<CartShipment>,
  is_updating: boolean
};
const Cart = ({cart_items, shipments, is_updating}: CartProps) => {
  useTrackScreenEffect('cart');
  const renderContents = () => {
    if (!cart_items || !shipments || is_updating){ // if the cart is undefined, hasn't been loaded yet
      const dispatch = useDispatch();
      const request_action = ui_actions.showDeliveryInfoModal();
      dispatch(request_action);
      return <FullPageLoader />;
    } else if (_.isEmpty(cart_items)){ // warn empty if no items (not using quantity, want chance to rescue when quantity === 0)
      return <EmptyCartWarning />;
    } else {
      return <CartView cart_items={cart_items} shipments={shipments} />;
    }
  };
  return (
    <div className="store-cart">
      {renderContents()}
    </div>
  );
};

const CartView = ({cart_items, shipments}) => (
  <React.Fragment>
    <MBLayout.StandardGrid>
      <h2 className="heading-row heading-row--has-subheader cart__page-heading">
        Your Cart
        <MBLink.Text href="/store/" className="heading-row__subheader">Continue Shopping »</MBLink.Text>
      </h2>
    </MBLayout.StandardGrid>
    <MBLayout.StandardGrid className="scCart_ShipmentOrder">
      <div className="scCart_ShipmentOrder_Order">
        <OrderPanel cart_items={cart_items} shipments={shipments} />
        <ShopRunnerPanel placement="top" />
      </div>
      <div className="scCart_ShipmentOrder_Shipment">
        <CartShareDiffWarning />
        {shipments.map(shipment => <ShipmentPanel key={shipment.supplier.id} shipment={shipment} />)}
        <BottomCTA cart_items={cart_items} shipments={shipments} />
        <ShopRunnerPanel placement="bottom" />
      </div>
    </MBLayout.StandardGrid>
    <CartContentLayout />
  </React.Fragment>
);

const BottomCTA = ({cart_items, shipments}) => {
  const item_count = cart_item_helpers.itemListQuantity(cart_items);
  const item_count_str = `${item_count} ${pluralize('item', item_count)}`;
  return (
    <div className="cart__bottom-cta">
      <p className="cart__bottom-cta__prompt">
        Subtotal ({item_count_str}):
        <span className="cart__bottom-cta__prompt__subtotal">{formatCurrency(cart_item_helpers.itemsSubtotal(cart_items))}</span>
      </p>
      <CheckoutButton cartValidToCheckout={cart_item_helpers.allMinimumsMet(shipments)} className="cart__bottom-cta__button" />
    </div>
  );
};

const EmptyCartWarning = () => (
  <MBLayout.StandardGrid className="center">
    <CartShareDiffWarning />
    <h3 className="heading-panel empty-cart-warning">Your Cart is Empty</h3>
    <br />
    <MBLink.View id="button-home" className="button" href="/store/">
      Continue Shopping
    </MBLink.View>
  </MBLayout.StandardGrid>
);

type ShopRunnerPanelProps = { placement: 'top' | 'bottom' };
const ShopRunnerPanel = ({placement}: ShopRunnerPanelProps) => {
  const hasShopRunnerTokenClass = hasShopRunnerToken() ? 'with-token' : '';
  return <div className={`cart-shoprunner cart-shoprunner--${placement} ${hasShopRunnerTokenClass}`} name="sr_headerDiv" />;
};

const CartSTP = () => {
  const findSupplier = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));
  const findCartItem = Ent.query(Ent.find('cart_item'), Ent.join('variant'), Ent.join('product_grouping'));

  return state => {
    const is_cart_fetching = cart_item_selectors.getFetchCartStatus(state, cart_item_selectors.getCartId(state)) === LOADING_STATUS;
    const is_cart_share_applying = cart_share_selectors.getApplyCartShareStatus(state, cart_share_selectors.getCurrentCartShareId(state)) === LOADING_STATUS;
    const cart_items = findCartItem(state, cart_item_selectors.getAllCartItemIds(state));
    const suppliers = findSupplier(state, supplier_selectors.currentSupplierIds(state));
    const shipments = cart_item_helpers.getShipments(cart_items, suppliers, supplier_selectors.selectedDeliveryMethods(state));
    return {
      cart_items,
      shipments,
      is_updating: _.isEmpty(suppliers) || is_cart_fetching || is_cart_share_applying
    };
  };
};
const CartContainer = connect(CartSTP)(Cart);

export default CartContainer;

