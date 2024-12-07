// @flow

import * as React from 'react';
import { MBText } from 'store/views/elements';
import DeliveryMethodIcon from './DeliveryMethodIcon';

type ShippingRequiredNotificationProps = {
  show: boolean
}

const ShippingRequiredNotification = ({ show }: ShippingRequiredNotificationProps) => {
  if (!show) return null;

  return (
    <div className="cm-shipping-required-notification">
      <DeliveryMethodIcon delivery_method_type="shipped" active />
      <MBText.P>Shipments typically arrive in 3-5 business days</MBText.P>
    </div>
  );
};

export default ShippingRequiredNotification;
