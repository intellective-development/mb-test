// @flow

import React, { Component } from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';

import type { Address } from 'store/business/address';
import { address_actions, address_selectors } from 'store/business/address';
import { supplier_actions, supplier_selectors } from 'store/business/supplier';
import { ui_selectors } from 'store/business/ui';
import { dispatchAction } from 'shared/dispatcher';

import connectRequestStatus from 'shared/utils/connect_request_status';
import AddressWaitlist from '../../../compounds/AddressWaitlist';
import { MBModal } from '../../../elements';
import AddressPage from './AddressPage';

type ExternalAddressEntryModalProps = {
  is_hidden: boolean,
  hideModal: () => void,

  // HOC props
  destination: string,
  current_address: Address,
  current_supplier_ids: Array<number>,
  trackRequestStatus: Function,
  createDeliveryAddress: Function,
  enterStore: Function,
  trackRequest: Function,
};
type ExternalAddressEntryModalState = { page: 'enter_address' | 'waitlist' };
const address_entry_default_state = { page: 'enter_address' };
class ExternalAddressEntryModal extends Component<ExternalAddressEntryModalProps, ExternalAddressEntryModalState> {
  state = address_entry_default_state;

  componentWillReceiveProps(next_props: ExternalAddressEntryModalProps){
    // reset when hiding the modal
    if (!this.props.is_hidden && next_props.is_hidden){
      this.setState(address_entry_default_state);
    }
  }

  submitAddress = (address: Address, resetAddressEntryState: () => void) => {
    const { current_supplier_ids, trackRequestStatus, createDeliveryAddress } = this.props;

    trackRequestStatus(
      createDeliveryAddress(address, {preferred_supplier_ids: current_supplier_ids}),
      this.navigateToDestination,
      () => {
        this.showWaitlist();
        resetAddressEntryState();
      }
    );
  }

  navigateToDestination = () => {
    return dispatchAction({
      actionType: 'navigate',
      destination: this.props.destination
    });
  }

  showWaitlist = () => this.setState({page: 'waitlist'})

  renderContentForPage(){
    const { page } = this.state;
    const { hideModal, current_address} = this.props;

    if (page === 'waitlist'){
      return (
        <AddressWaitlist
          routeBack={() => this.setState({page: 'enter_address'})}
          hideModal={hideModal} />
      );
    } else {
      return (
        <AddressPage
          current_address={current_address}
          submitAddress={this.submitAddress}
          hideModal={hideModal} />
      );
    }
  }
  render(){
    return (
      <MBModal.Modal
        show={!this.props.is_hidden}
        onHide={this.props.hideModal}
        size="large" >
        {this.renderContentForPage()}
      </MBModal.Modal>
    );
  }
}

const ExternalAddressEntryModalSTP = () => {
  const findCurrentAddress = Ent.find('address');

  return (state) => {
    const current_address = findCurrentAddress(state, address_selectors.currentDeliveryAddressId(state));
    const current_supplier_ids = supplier_selectors.currentSupplierIds(state);
    const destination = ui_selectors.addressEntryModalDestination(state) || '/';

    return {current_address, current_supplier_ids, destination};
  };
};
const ExternalAddressEntryModalDTP = {
  createDeliveryAddress: address_actions.createDeliveryAddress,
  enterStore: supplier_actions.enterStore
};
const ExternalAddressEntryModalContainer = connect(ExternalAddressEntryModalSTP, ExternalAddressEntryModalDTP)(connectRequestStatus(ExternalAddressEntryModal));

export default ExternalAddressEntryModalContainer;
