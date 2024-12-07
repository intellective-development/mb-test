// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { address_selectors } from 'store/business/address';
import { ui_actions, ui_selectors } from 'store/business/ui';

import CurrentDeliveryInfoModal from './CurrentDeliveryInfoModal';
import ExternalAddressEntryModal from './ExternalAddressEntryModal';

type DeliveryInfoModalProps = {
  is_hidden: boolean,
  has_delivery_address: boolean,
  hideModal: () => void
}
const DeliveryInfoModal = ({is_hidden, has_delivery_address, hideModal}: DeliveryInfoModalProps) => {
  // these components need to stay mounted in order to properly facilitate deep link redirects,
  // they handle their own hiding and state resetting

  const can_show_current = has_delivery_address; // have an address and inside the store
  return (
    <div>
      <CurrentDeliveryInfoModal hideModal={hideModal} is_hidden={!can_show_current || is_hidden} />
      <ExternalAddressEntryModal hideModal={hideModal} is_hidden={can_show_current || is_hidden} />
    </div>
  );
};

const DeliveryInfoSTP = (state) => ({
  is_hidden: !ui_selectors.isDeliveryInfoModalShowing(state),
  has_delivery_address: address_selectors.hasDeliveryAddress(state)
});
const DeliveryInfoDTP = {hideModal: ui_actions.hideDeliveryInfoModal};
const DeliveryInfoModalContainer = connect(DeliveryInfoSTP, DeliveryInfoDTP)(DeliveryInfoModal);

export default DeliveryInfoModalContainer;
export const __private__ = {
  DeliveryInfoModal
};
