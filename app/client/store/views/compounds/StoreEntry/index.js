// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';

import { address_actions, address_selectors } from 'store/business/address';
import type { Address, AddressRoutingOptions } from 'store/business/address';
import { supplier_selectors } from 'store/business/supplier';
import { dispatchAction } from 'shared/dispatcher';

import connectRequestStatus from 'shared/utils/connect_request_status';
import AddressEntry from 'store/views/compounds/AddressEntry';
import { AddressWaitlistModal } from 'store/views/compounds/AddressWaitlist';

// TODO: similarities with CurrentDeliveryInfo/AddressSection

type StoreEntryProps = {
  autofocus?: boolean,
  submit_button_text: string,
  destination?: string,
  routing_options: AddressRoutingOptions,
  show_address_entry_placeholder?: boolean,

  current_address: ?Address,
  current_supplier_ids: Array<number>,
  createDeliveryAddress: Function,
  trackRequestStatus: Function
}
type StoreEntryState = {
  waitlist_is_showing: boolean
};
class StoreEntry extends React.Component<StoreEntryProps, StoreEntryState> {
  state = { waitlist_is_showing: false }

  static defaultProps = {
    routing_options: {}
  }

  submitAddress = (address: Address, resetAddressEntryState: () => void) => {
    const { routing_options, current_supplier_ids, trackRequestStatus, createDeliveryAddress } = this.props;

    trackRequestStatus(
      createDeliveryAddress(address, {preferred_supplier_ids: current_supplier_ids, ...routing_options}),
      this.navigateToDestination,
      () => {
        this.showWaitlist();
        resetAddressEntryState();
      }
    );
  }

  navigateToDestination = () => {
    if (!this.props.destination) return null;

    return dispatchAction({
      actionType: 'navigate',
      destination: this.props.destination
    });
  }

  showWaitlist = () => this.setState({waitlist_is_showing: true})
  hideWaitlist = () => this.setState({waitlist_is_showing: false})

  render(){
    const { className, current_address, submit_button_text, show_address_entry_placeholder } = this.props;

    return (
      <div className={className}>
        <AddressEntry
          autofocus={this.props.autofocus}
          submitAddress={this.submitAddress}
          current_address={current_address}
          submit_button_text={submit_button_text}
          can_submit_current
          show_placeholder={show_address_entry_placeholder} />
        <AddressWaitlistModal
          hideModal={this.hideWaitlist}
          isHidden={!this.state.waitlist_is_showing} />
      </div>
    );
  }
}

const StoreEntrySTP = () => {
  const findAddress = Ent.find('address');

  return (state) => {
    const current_address = findAddress(state, address_selectors.currentDeliveryAddressId(state));
    const current_supplier_ids = supplier_selectors.currentSupplierIds(state);

    return {current_address, current_supplier_ids};
  };
};
const StoreEntryDTP = {createDeliveryAddress: address_actions.createDeliveryAddress};
const StoreEntryContainer = connect(StoreEntrySTP, StoreEntryDTP)(connectRequestStatus(StoreEntry));

export default StoreEntryContainer;
