// @flow

import * as React from 'react';
import classNames from 'classnames';
import formatCurrency from 'shared/utils/format_currency';
import pluralize from 'shared/utils/pluralize';
import CheckoutButton from 'cart/checkout_button';
import type { CartItem, CartShipment } from 'store/business/cart_item';
import { cart_item_helpers } from 'store/business/cart_item';

type OrderPanelProps = {cart_items: Array<CartItem>, shipments: Array<CartShipment>};
const OrderPanel = ({cart_items, shipments}: OrderPanelProps) => {
  const cart_valid_to_checkout = cart_item_helpers.allMinimumsMet(shipments);

  return (
    <div>
      <div className="panel-group">
        <div className="dark-panel center cart-order-panel">
          <CheckoutPrompt shipments={shipments} cartValidToCheckout={cart_valid_to_checkout} />
          <SubtotalListing shipments={shipments} items={cart_items} />
          <CheckoutButton cartValidToCheckout={cart_valid_to_checkout} className="cart-order-panel__button expand" />
        </div>
        <div className="dark-panel cart-order-legal">
          <p className="center legal">Sales tax, tip, delivery fees and promo codes will be applied when you check out.</p>
        </div>
      </div>
      <GiftPanel />
    </div>
  );
};

const getValidCartPromptText = (shipments) => {
  if (shipments.length <= 1){
    return '';
  } else {
    return `Your order will be delivered in ${shipments.length} parts.`;
  }
};
const getInvalidCartPromptText = (shipments) => {
  if (shipments.length === 1){
    const supplier_name = shipments[0].supplier.name;
    return `You have not reached ${supplier_name}'s delivery minimum.`;
  } else {
    return 'You have not reached the delivery minimum for one or more suppliers.';
  }
};
const CheckoutPrompt = ({shipments = [], cartValidToCheckout}) => {
  let prompt_text;

  const prompt_classes = classNames('cart-order-panel__prompt', {
    'cart-order-panel__error': !cartValidToCheckout,
    'hidden': !prompt_text
  });

  if (cartValidToCheckout){
    prompt_text = getValidCartPromptText(shipments);
  } else {
    prompt_text = getInvalidCartPromptText(shipments);
  }

  return <div className={prompt_classes}>{prompt_text}</div>;
};

const SubtotalListing = ({items = []}) => {
  const item_count = cart_item_helpers.itemListQuantity(items);
  const item_count_str = `${item_count} ${pluralize('item', item_count)}`;

  return (
    <div className="cart-order-panel__subtotal">
      <span>Subtotal ({item_count_str}):</span>
      <span>{formatCurrency(cart_item_helpers.itemsSubtotal(items))}</span>
    </div>
  );
};

const GiftPanel = () => (
  <div className="show-for-medium-up panel gift">
    <h4>Sending a gift?</h4>
    <p>Proceed to checkout to select gift options.</p>
  </div>
);

export default OrderPanel;
