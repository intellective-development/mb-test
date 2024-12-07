// @flow

import * as React from 'react';
import { formatDateLong } from '@minibar/store-business/src/utils/format_date';
import type { CartShare } from 'store/business/cart_share';
import type { Order } from 'store/business/order';
import { MBCardCarousel } from 'store/views/elements';
import PreviousOrder from './PreviousOrder';
import type { PreviousOrderProps } from './PreviousOrder';

type PreviousOrdersProps = {
  cart_shares: CartShare[],
  orders: Order[]
}

const makeOrderProps = (cart_shares): PreviousOrderProps[] => cart_shares.map(cart_share => {
  return { cart_share_id: cart_share.id };
});

const PreviousOrders = ({ cart_shares }: PreviousOrdersProps) => {
  const previous_orders = makeOrderProps(cart_shares);

  return (
    <MBCardCarousel
      cards={previous_orders}
      selectKey={order_props => `${order_props.cart_share_id}_${order_props.order_number}`}
      selectTitle={order_props => formatDateLong(order_props.completed_at)}
      renderCard={order_props => (<PreviousOrder {...order_props} />)} />
  );
};

export default PreviousOrders;
