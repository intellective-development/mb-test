// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { dispatchAction } from 'shared/dispatcher';
import { address_actions, address_selectors } from 'store/business/address';
import { supplier_selectors } from 'store/business/supplier';
import type { Address } from 'store/business/address';
import { analytics_actions } from 'store/business/analytics';

import connectRequestStatus from 'shared/utils/connect_request_status';
import AddressEntry from '../../../compounds/AddressEntry';
import GiftPrompt from '../../../compounds/GiftPrompt';

// TODO: include user addresses

type AddressSectionProps = {
  deliveryInfoRouteTo: Function,

  current_address: Address,
  current_supplier_ids: Array<number>,
  createDeliveryAddress: typeof address_actions.createDeliveryAddress,
  trackRequestStatus: Function,
  trackAddressModal(location: string): void;
};
class AddressSection extends React.Component<AddressSectionProps> {
  address_entry_ref: Object

  componentDidMount(){
    this.props.trackAddressModal('view_in_store');
  }

  submitAddress = (address: Address, resetAddressEntryState: () => void, destinationLocation: string = '/') => {
    const { current_supplier_ids, createDeliveryAddress, trackRequestStatus, trackAddressModal } = this.props;

    trackRequestStatus(
      createDeliveryAddress(address, {preferred_supplier_ids: current_supplier_ids}),
      () => {
        this.navigateToDestination(destinationLocation);
        resetAddressEntryState();
      },
      () => {
        this.showWaitlist();
        resetAddressEntryState();
      }
    );

    trackAddressModal('change_address');
  }

  navigateToDestination = (destination) => {
    dispatchAction({
      actionType: 'navigate',
      destination: destination
    });
  }

  showWaitlist = () => {
    this.props.deliveryInfoRouteTo('address_waitlist');
  }

  render(){
    const {current_address} = this.props;

    return (
      <div className="currdel__address__container">
        <GiftPrompt />
        <AddressEntry
          button_hidden
          submit_button_text="Go"
          submitAddress={this.submitAddress}
          current_address={current_address}
          can_submit_current={false} />
      </div>
    );
  }
}

const AddressSectionSTP = () => {
  const findAddress = Ent.find('address');

  return (state) => {
    const current_address = findAddress(state, address_selectors.currentDeliveryAddressId(state));
    const current_supplier_ids = supplier_selectors.currentSupplierIds(state);

    return {current_address, current_supplier_ids};
  };
};
const AddressSectionDTP = {
  createDeliveryAddress: address_actions.createDeliveryAddress,
  trackAddressModal: (location: string) => analytics_actions.track({ category: 'address_modal', action: location })
};
const AddressSectionContainer = connect(AddressSectionSTP, AddressSectionDTP)(connectRequestStatus(AddressSection));

export default AddressSectionContainer;
