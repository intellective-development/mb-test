// @flow

import { map, uniq } from 'lodash';
import * as React from 'react';

import ItemSummary from 'cart/shipment_panel/item_summary';
import SupplierSummary from 'cart/shipment_panel/supplier_summary';
import DeliverySummary from 'cart/shipment_panel/delivery_summary';
import DeliveryCostPrompt from 'cart/shipment_panel/delivery_cost_prompt';
import MeetMinimumContentModule from 'cart/shipment_panel/meet_minimum_content_module';

type ShipmentPanelProps = {shipment: Object};
const ShipmentPanel = ({shipment}: ShipmentPanelProps) => {
  const excludeDelivery = map(
    shipment.items,
    ({ product_grouping }) =>
      uniq(product_grouping.tags).includes('bartender')
  ).every(t => t === true);

  return (
    <table className="shipment-table"><tbody>
      <SupplierSummary shipment={shipment} />
      {!excludeDelivery && (
        <tr>
          <td colSpan="5">
            {shipment.supplier.delivery_methods.map(delivery_method => (
              <DeliverySummary
                shipment={shipment}
                delivery_method={delivery_method}
                is_changeable={shipment.supplier.delivery_methods.length > 1}
                selected={delivery_method.id === shipment.delivery_method.id}
                key={delivery_method.id} />
            ))}
          </td>
        </tr>
      )}
      <DeliveryCostPrompt shipment={shipment} />
      {shipment.items.map(item => <ItemSummary item={item} key={item.variant.id} />)}
      <MeetMinimumContentModule shipment={shipment} supplier_id={shipment.supplier.id} />
    </tbody></table>
  );
};

export default ShipmentPanel;
