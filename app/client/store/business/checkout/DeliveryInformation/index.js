import React, { Fragment, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { Link } from 'react-router-dom';
import { selectShippingOptions, SetCheckoutAddressEditing } from 'modules/checkout/checkout.dux';
import { useCheckoutOrder, useAllShipmentsReady } from 'modules/checkout/checkout.hooks';
import Scheduling from './Scheduling';
import DeliveryAddress from './DeliveryAddress';
import PickupDetails from './PickupDetails';
import Panel from '../shared/Panel';
import PanelTitle from '../shared/PanelTitle';

const DeliveryInformation = () => {
  const dispatch = useDispatch();
  const { hasShipping, hasPickup } = useSelector(selectShippingOptions);
  const { cartReady, orderItems } = useCheckoutOrder();
  const areAllShipmentsReady = useAllShipmentsReady();

  // Clear editing flag on mount
  useEffect(() => {
    dispatch(SetCheckoutAddressEditing(false));
  }, []);

  useEffect(() => {
    if (!areAllShipmentsReady){
      // set timeout makes it occur in the next tick
      setTimeout(dispatch(SetCheckoutAddressEditing(true)));
    }
  }, [areAllShipmentsReady]);

  if (!cartReady){
    return (
      <Panel>
        <PanelTitle>
          <div style={{ flex: 1, flexDirection: 'column', display: 'flex', alignItems: 'center' }}>
            Getting your cart information
          </div>
        </PanelTitle>
      </Panel>
    );
  }

  if (!orderItems.length){
    return (
      <Panel>
        <PanelTitle>
          <div style={{ flex: 1, flexDirection: 'column', display: 'flex', alignItems: 'center' }}>
            Your cart is empty
            <br />
            <Link to="/store">Shop more</Link>
          </div>
        </PanelTitle>
      </Panel>
    );
  }

  return (
    <Fragment>
      <Scheduling />
      {hasShipping && <DeliveryAddress />}
      {hasPickup && <PickupDetails />}
    </Fragment>
  );
};

export default DeliveryInformation;
