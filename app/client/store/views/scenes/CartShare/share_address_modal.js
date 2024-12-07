// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { push } from 'connected-react-router';
import { supplier_selectors } from 'store/business/supplier';
import { cart_share_actions, cart_share_selectors } from 'store/business/cart_share';
import type { CartShare as CartShareEntity } from 'store/business/cart_share';
import type { Address } from 'store/business/address';
import { request_status_constants } from 'store/business/request_status';

import EnterShareAddress from './share_address_modal_enter';
import AddressWaitlist from '../../compounds/AddressWaitlist';
import { MBModal } from '../../elements';

const { SUCCESS_STATUS } = request_status_constants;

type ShareAddressModalProps = {
  share: CartShareEntity,
  current_address: Address,
  applyCartShare: (CartShareEntity, Address) => void,
  push: (string) => void,
  apply_share_success: boolean
};
type ShareAddressModalState = {address_entry_state: 'enter' | 'confirm' | 'waitlist'};
// Note that this modal is undismissable.
class ShareAddressModal extends React.Component<ShareAddressModalProps, ShareAddressModalState> {
  constructor(props){
    super(props);
    this.state = {address_entry_state: _.isEmpty(this.getAddress()) ? 'enter' : 'confirm'};
  }

  componentWillReceiveProps(next_props){
    if (this.props.supplier_fetch_loading && next_props.supplier_fetch_waitlist_error){
      this.setState({address_entry_state: 'waitlist'});
    }
    if (!this.props.apply_share_success && next_props.apply_share_success){
      // NOTE: move to nav epic? this is not my favorite thing in the world, but, well, here we are.
      next_props.push('/store/cart');
    }
  }

  getAddress = () => {
    const {share, current_address} = this.props;
    // if no address on the share, try to grab the users current address
    let order_data = {};
    if (share.order && share.order.shipping_address){
      const { id, local_id, address2, phone } = share.order.shipping_address;
      order_data = {
        id_copy: id,
        local_id,
        address2,
        phone
      };
    }
    return _.isEmpty(share.address) ? current_address : { ...share.address, ...order_data };
  };

  renderContentForPage = () => {
    const {share, applyCartShare} = this.props;
    switch (this.state.address_entry_state){
      case 'waitlist':
        return <AddressWaitlist routeBack={() => this.setState({address_entry_state: 'enter'})} />;
      case 'enter':
      default:
        return (
          <EnterShareAddress
            current_address={this.getAddress()}
            submitAddress={(address) => applyCartShare(share, address)} />
        );
    }
  };

  render(){
    return (
      <MBModal.Modal size="medium" show>
        {this.renderContentForPage()}
      </MBModal.Modal>
    );
  }
}

const ShareAddressModalSTP = (state) => ({
  supplier_fetch_loading: supplier_selectors.fetchLoading(state),
  supplier_fetch_waitlist_error: supplier_selectors.fetchError(state) && supplier_selectors.shouldJoinWaitlist(state),
  apply_share_success: cart_share_selectors.getApplyCartShareStatus(state, cart_share_selectors.getCurrentCartShareId(state)) === SUCCESS_STATUS
});
const ShareAddressModalDTP = {
  applyCartShare: cart_share_actions.applyCartShare,
  push: push
};
const ShareAddressModalContainer = connect(ShareAddressModalSTP, ShareAddressModalDTP)(ShareAddressModal);

export default ShareAddressModalContainer;
