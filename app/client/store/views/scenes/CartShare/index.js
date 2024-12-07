// @flow

import React, { useEffect } from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { address_selectors } from 'store/business/address';
import { cart_share_actions, cart_share_selectors } from 'store/business/cart_share';
import type { CartShare as CartShareEntity } from 'store/business/cart_share';
import type { Address } from 'store/business/address';
import { request_status_constants } from 'store/business/request_status';

import FullPageLoader from 'shared/components/full_page_loader';
import ShareAddressModal from './share_address_modal';
import ShareItemTable from './share_item_table';

type CartShareProps = {
  share: CartShareEntity,
  loading: boolean,
  error: boolean,
  current_address: Address,
  fetchCartShare: () => void,
  cart_share_id: number
};
const CartShare = ({
  share = {}, loading, current_address, cart_share_id, error, fetchCartShare
}: CartShareProps) => {
  useEffect(() => {
    fetchCartShare(cart_share_id);
  }, [cart_share_id, fetchCartShare]);
  if (loading) return <FullPageLoader />;

  // TODO: show error
  if (error) return null;

  return (
    <div>
      <ShareAddressModal share={share} current_address={current_address} />
      <ShareItemTable items={share.items} />
    </div>
  );
};

const CartShareSTP = () => {
  const findAddress = Ent.find('address');
  const findCartShare = Ent.find('cart_share');

  return (state, { cart_share_id }) => {
    const fetch_status = cart_share_selectors.getFetchCartShareStatus(state, cart_share_id);
    return {
      cart_share_id,
      fetch_status,
      loading: fetch_status === request_status_constants.LOADING_STATUS,
      error: fetch_status === request_status_constants.ERROR_STATUS,
      share: findCartShare(state, cart_share_selectors.getCurrentCartShareId(state)),
      current_address: findAddress(state, address_selectors.currentDeliveryAddressId(state))
    };
  };
};
const CartShareDTP = { fetchCartShare: cart_share_actions.fetchCartShare };

export default connect(CartShareSTP, CartShareDTP)(CartShare);
