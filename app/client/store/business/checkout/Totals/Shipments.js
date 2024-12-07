import React from 'react';
import { mapValues, values } from 'lodash';
import { useSelector } from 'react-redux';
import { selectShipmentsGrouped } from 'modules/cartItem/cartItem.dux';
import ShipmentPanel from '../Shipments/ShipmentPanel';

const renderShipmentPanel = (shipment, supplierId) => {
  return (
    <ShipmentPanel
      key={supplierId}
      shipment={shipment}
      supplierId={supplierId} />
  );
};

const Shipments = () => {
  const shipments = useSelector(selectShipmentsGrouped);
  return values(mapValues(shipments, renderShipmentPanel));
};

export default Shipments;
