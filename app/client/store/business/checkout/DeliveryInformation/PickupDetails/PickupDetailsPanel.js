import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { css } from '@amory/style/umd/style';
import { SetCheckoutAddressEditing } from 'modules/checkout/checkout.actions';
import { selectPickupDetails } from 'modules/checkout/checkout.selectors';

import styles from '../../Checkout.css.json';

import Panel from '../../shared/Panel';
import EditButton from '../../shared/EditButton';
import PanelTitle from '../../shared/PanelTitle';

const DeliveryAddressPanel = () => {
  const dispatch = useDispatch();

  const {
    isGift,
    name,
    phone
  } = useSelector(selectPickupDetails) || {};

  const setEditing = editing => dispatch(SetCheckoutAddressEditing(editing));

  return (
    <Panel id="delivery-address">
      <div className={css(styles.header)}>
        <PanelTitle
          id="delivery-address"
          isComplete>
          Pickup Details
        </PanelTitle>
        <EditButton onClick={() => setEditing(true)}>
          Edit
        </EditButton>
      </div>
      <div
        className={css({
          padding: '5px 10px 10px'
        })}>
        {isGift && (
          <div className={css(styles.deliverysummary)}>
            Gift wrapped (free).
          </div>
        )}
        <div className={css(styles.deliverysummary)}>
          {name}
        </div>
        <div className={css(styles.deliverysummary)}>
          {phone}
        </div>
      </div>
    </Panel>
  );
};

export default DeliveryAddressPanel;
