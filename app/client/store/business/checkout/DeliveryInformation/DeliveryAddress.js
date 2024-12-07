import { css } from '@amory/style/umd/style';
import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { join, compact } from 'lodash';
import { ResetCheckoutAddress, selectCheckoutAddressEditing, selectCheckoutAddress, SetCheckoutAddressEditing } from 'modules/checkout/checkout.dux';
import { selectCurrentDeliveryAddress } from 'modules/address/address.dux';
import DeliveryAddressPanel from './DeliveryAddressPanel';
import DeliveryAddressForm from './DeliveryAddressForm';
import { useToggle } from '../shared/use-toggle';
import Panel from '../shared/Panel';
import EditButton from '../shared/EditButton';
import PanelTitle from '../shared/PanelTitle';
import icon from '../shared/MBIcon/MBIcon';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';

const DeliveryAddress = () => {
  // TODO: move to hook
  const dispatch = useDispatch();
  const address = useSelector(selectCurrentDeliveryAddress) || {};
  const addressLine = join(compact([address.address1]), ', ');
  const formattedAddress = join(compact([addressLine, address.city, address.state, address.zip_code]), ', ');
  const checkoutAddress = useSelector(selectCheckoutAddress) || {};
  const shouldEdit = useSelector(selectCheckoutAddressEditing);
  const checkoutAddressLine = join(compact([checkoutAddress.address1]), ', ');
  const formattedCheckoutAddress = join(compact([checkoutAddressLine, checkoutAddress.city, checkoutAddress.state, checkoutAddress.zip_code]), ', ');
  const [toggle, setToggle] = useToggle(true);
  const setEditing = editing => dispatch(SetCheckoutAddressEditing(editing));

  useEffect(() => {
    if (formattedAddress !== formattedCheckoutAddress){
      dispatch(ResetCheckoutAddress());
    }
  }, [dispatch, formattedAddress, formattedCheckoutAddress]);

  return (
    <Panel id="delivery-address">
      <div className={css(styles.header)}>
        <PanelTitle id="delivery-address" isComplete={!shouldEdit}>
          Delivery Information
        </PanelTitle>
        {shouldEdit || <EditButton onClick={() => setEditing(true)}>
          Edit
        </EditButton>}
        <button
          className={css([
            unstyle.button,
            icon({
              name: toggle ? 'arrowDown' : 'arrowUp'
            }),
            styles.paneltoggle
          ])}
          onClick={setToggle}
          type="button" />
      </div>

      <div
        aria-expanded={toggle}
        aria-hidden={!toggle}
        className={css(toggle ? {} : { display: 'none' })}>
        {shouldEdit ? <DeliveryAddressForm /> : <DeliveryAddressPanel />}
      </div>
    </Panel>
  );
};

export default DeliveryAddress;
