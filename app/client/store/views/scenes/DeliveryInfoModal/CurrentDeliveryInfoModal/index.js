// @flow

import * as React from 'react';

import DeliveryInfo from './DeliveryInfo';
import SupplierMap from './SupplierMap';
import SupplierSwitching from './SupplierSwitching';
import AddressWaitlist from '../../../compounds/AddressWaitlist';
import { MBModal } from '../../../elements';

type CurrentDeliveryInfoModalProps = {
  is_hidden: boolean,
  hideModal: () => void
};
type CurrentDeliveryInfoModalPage = 'delivery_info' | 'address_waitlist' | 'supplier_switching' | 'supplier_map';
type CurrentDeliveryInfoModalState = { page: CurrentDeliveryInfoModalPage, page_params: {supplier_id?: number}; };
const default_state = { page: 'delivery_info', page_params: {} };

class CurrentDeliveryInfoModal extends React.Component<CurrentDeliveryInfoModalProps, CurrentDeliveryInfoModalState> {
  state = default_state;

  componentWillReceiveProps(next_props: CurrentDeliveryInfoModalProps){
    if (!this.props.is_hidden && next_props.is_hidden){
      this.setState(default_state); // when dismissing the modal, reset it to the initial page
    }
  }

  deliveryInfoRouteTo = (page: CurrentDeliveryInfoModalPage, page_params: Object = {}) => {
    this.setState({page, page_params});
  }

  renderContentForPage(){
    const { page, page_params } = this.state;
    const { hideModal } = this.props;

    const routeBack = () => this.deliveryInfoRouteTo('delivery_info');

    switch (page){
      case 'delivery_info':
        return <DeliveryInfo deliveryInfoRouteTo={this.deliveryInfoRouteTo} hideModal={hideModal} />;
      case 'supplier_switching':
        return <SupplierSwitching supplier_id={page_params.supplier_id} routeBack={routeBack} hideModal={hideModal} />;
      case 'supplier_map':
        return <SupplierMap supplier_id={page_params.supplier_id} routeBack={routeBack} hideModal={hideModal} />;
      case 'address_waitlist':
        return <AddressWaitlist routeBack={routeBack} hideModal={hideModal} />;
      default:
        return null;
    }
  }

  render(){
    const { is_hidden, hideModal } = this.props;

    return (
      <MBModal.Modal size="large" show={!is_hidden} onHide={hideModal}>
        {this.renderContentForPage()}
      </MBModal.Modal>
    );
  }
}

export default CurrentDeliveryInfoModal;
export { CurrentDeliveryInfoModal }; // for testing
