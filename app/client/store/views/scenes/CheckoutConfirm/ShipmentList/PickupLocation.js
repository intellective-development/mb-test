// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import I18n from 'store/localization';
import { address_helpers } from 'store/business/address';
import { delivery_method_constants } from 'store/business/delivery_method';
import { supplier_helpers } from 'store/business/supplier';
import type { Shipment } from 'legacy_store/models/Shipment';
import { ui_actions } from 'store/business/ui';

import { MBText, MBTouchable } from '../../../elements';

type PickupLocationProps = {shipment: Shipment, showSupplierMap: Function};
export const PickupLocation = ({shipment, showSupplierMap}: PickupLocationProps) => {
  if (shipment.delivery_method.type !== delivery_method_constants.PICKUP) return null;

  return (
    <MBTouchable className="csl__pickup__container" onClick={() => showSupplierMap(shipment.supplier.id)} >
      <MBText.P className="csl__pickup__section-label">{I18n.t('ui.body.checkout_shipment.pickup_location_prompt')}</MBText.P>
      <MBText.P className="csl__pickup__address">
        {address_helpers.formatStreetAndCity(shipment.supplier.address)}
        ・{supplier_helpers.formatDistance(shipment.supplier)}
      </MBText.P>
    </MBTouchable>
  );
};

const PickupLocationDTP = {showSupplierMap: ui_actions.showSupplierMapModal};
const PickupLocationContainer = connect(null, PickupLocationDTP)(PickupLocation);

export default PickupLocationContainer;
