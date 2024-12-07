// @flow

import * as React from 'react';
import I18n from 'store/localization';
import formatCurrency from 'shared/utils/format_currency';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import type { Shipment } from 'legacy_store/models/Shipment';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { hasShopRunnerToken } from 'shared/utils/shop_runner';

import { MBText } from 'store/views/elements';

type DeliveryCostPromptProps = {shipment: Shipment};
const DeliveryCostPrompt = ({shipment}: DeliveryCostPromptProps) => {
  const subtotal = shipment_helpers.shipmentSubtotal(shipment);

  if (delivery_method_helpers.belowMinimum(shipment.delivery_method, subtotal)){
    return (
      <tr>
        <td colSpan="5" className="sp__cost__minimum-container">
          <MBText.Span className="sp__cost__minimum-text">
            {shipment_helpers.meetMinimumMessage(shipment)}
          </MBText.Span>
        </td>
      </tr>
    );
  } else if (!hasShopRunnerToken() && delivery_method_helpers.belowFreeThreshold(shipment.delivery_method, subtotal)){
    return (
      <tr>
        <td colSpan="5" className="sp__cost__threshold-container">
          <MBText.Span className="sp__cost__threshold-text">
            {I18n.t('ui.body.cart.under_delivery_free_threshold', {
              delivery_type: delivery_method_helpers.displayName(shipment.delivery_method).toLowerCase(),
              free_delivery_threshold: formatCurrency(shipment.delivery_method.free_delivery_threshold, {truncate: true})
            })}
          </MBText.Span>
        </td>
      </tr>
    );
  } else {
    return null;
  }
};

export default DeliveryCostPrompt;
