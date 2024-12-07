// @flow
import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import { connect } from 'react-redux';
import { address_selectors } from 'store/business/address';
import { ui_actions } from 'store/business/ui';

import { MBText, MBTouchable } from '../../../elements';
import DeliveryInfo from '../shared/DeliveryInfo';

import styles from './DeliveryLink.scss';

const cn = bindClassNames(styles);

type DeliveryLinkProps = {
  showDeliveryInfoModal: () => void,
  has_delivery_address: boolean
};

const DeliveryLink = ({has_delivery_address, showDeliveryInfoModal}: DeliveryLinkProps) => {
  const handleClick = () => {
    showDeliveryInfoModal(location.pathname);
  };

  return (
    <MBTouchable
      role="button"
      onClick={handleClick}
      className={cn('cmDeliveryLink', {cmDeliveryLink__NoAddress: !has_delivery_address})}>
      <DeliveryInfo />
      <MBText.Span className={cn('cmDeliveryLink_Change', {cmDeliveryLink_Change__NoAddress: !has_delivery_address})}>
        Change
      </MBText.Span>
    </MBTouchable>
  );
};


const DeliveryLinkSTP = (state) => ({has_delivery_address: address_selectors.hasDeliveryAddress(state)});
const DeliveryLinkDTP = {showDeliveryInfoModal: ui_actions.showDeliveryInfoModal};
const DeliveryLinkContainer = connect(DeliveryLinkSTP, DeliveryLinkDTP)(DeliveryLink);

export default DeliveryLinkContainer;
