// @flow
import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { request_status_constants } from 'store/business/request_status';
import type { RequestStatus } from 'store/business/request_status';
import type { CartShare } from 'store/business/cart_share';
import { cart_share_actions, cart_share_selectors } from 'store/business/cart_share';

type WithCartShareProps = {
  cart_share_id: number,
  render: ({ cart_share: CartShare, is_loading: boolean }) => React.Node,
  // From STP
  fetch_status: RequestStatus,
  cart_share: CartShare,
  // From DTP
  fetchCartShare: typeof cart_share_actions.fetchCartShare
};

class WithCartShare extends React.Component<WithCartShareProps> {
  componentDidMount(){
    this.loadCartShare(this.props);
  }

  componentWillReceiveProps(next_props){
    this.loadCartShare(next_props);
  }

  loadCartShare = (props: WithCartShareProps) => {
    const { fetchCartShare, cart_share_id, fetch_status } = props;
    const has_cart_share_id = cart_share_id !== undefined && !_.isNil(cart_share_id);
    const is_pending = fetch_status === request_status_constants.PENDING_STATUS;
    const is_loading = fetch_status === request_status_constants.LOADING_STATUS;
    const has_error = fetch_status === request_status_constants.ERROR_STATUS;
    const is_loaded = fetch_status === request_status_constants.SUCCESS_STATUS;

    if (has_cart_share_id && !is_pending && !is_loading && !has_error && !is_loaded){
      fetchCartShare(cart_share_id);
    }
  }

  render(){
    const { render, cart_share, fetch_status } = this.props;
    const is_loading = fetch_status === request_status_constants.LOADING_STATUS;
    const has_error = fetch_status === request_status_constants.ERROR_STATUS;

    if (has_error){ return null; }
    return render({ cart_share, is_loading });
  }
}

const WithCartShareSTP = () => {
  const findCartShare = Ent.find('cart_share');

  return (state, { cart_share_id }) => ({
    cart_share: findCartShare(state, cart_share_id),
    fetch_status: cart_share_selectors.getFetchCartShareStatus(state, cart_share_id)
  });
};

const WithCartShareDTP = {
  fetchCartShare: cart_share_actions.fetchCartShare
};

export default connect(WithCartShareSTP, WithCartShareDTP)(WithCartShare);
