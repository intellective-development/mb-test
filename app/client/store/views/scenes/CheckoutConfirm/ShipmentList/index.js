// @flow

import * as React from 'react';
import I18n from 'store/localization';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { connect } from 'react-redux';
import connectToObservables from 'shared/components/higher_order/connect_observables';
import { orderStream } from 'legacy_store/models/Order';
import { order_helpers } from 'store/business/order';
import { cart_item_selectors } from 'store/business/cart_item';
import { supplier_selectors } from 'store/business/supplier';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import formatCurrency from 'shared/utils/format_currency';
import { analytics_actions /*, analytics_helpers */} from 'store/business/analytics';

import { MBText } from '../../../elements';
import DeliveryInfo from './DeliveryInfo';
import ItemList from './ItemList';
import PickupLocation from './PickupLocation';
import SchedulingPicker from './SchedulingPicker';

export class ShipmentList extends React.PureComponent {
  /*componentDidMount(){
    const { cart_items = [], trackEvent } = this.props;
    TODO: cart_items.forEach(({ product_grouping, variant, quantity }) => {
      trackEvent({
        action: 'checkout_place_order_in_cart',
        content_type: 'product',
        items: [analytics_helpers.getCartItemData(product_grouping, variant, quantity)]
      });
    });
  }*/

  render(){
    const {shipments = []} = this.props;
    return (
      <div>
        {shipments.map(shipment => (
          <ShipmentListItem
            shipment={shipment}
            key={shipment.supplier.id} />
        ))}
      </div>
    );
  }
}

type ShipmentListItemProps = {shipment: Object};
const ShipmentListItem = ({shipment}: ShipmentListItemProps) => {
  return (
    <div className="panel-group">
      <div className="panel heading">
        <ShipmentHeader shipment={shipment} />
      </div>
      <div className="panel">
        <DeliveryInfo shipment={shipment} />
        <PickupLocation shipment={shipment} />
        <SchedulingPicker shipment={shipment} />
      </div>
      <div className="panel">
        <ItemList items={shipment.items} />
      </div>
    </div>
  );
};

const ShipmentHeader = ({shipment}) => {
  return (
    <div>
      <MBText.H2 className="csl__panel_heading">{shipment.supplier.name}</MBText.H2>
      <MBText.H3 className="csl__panel_subheading">
        {I18n.t('ui.body.checkout_shipment.items', {
          count: shipment_helpers.shipmentItemCount(shipment) || 0
        })}
        &ensp;&ndash;&ensp;
        {formatCurrency(shipment_helpers.shipmentSubtotal(shipment))}
      </MBText.H3>
    </div>
  );
};

export const ShipmentListSTP = () => {
  const findCartItems = Ent.query(Ent.find('cart_item'), Ent.join('variant'), Ent.join('product_grouping'));
  const findSuppliers = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));
  return (state, {order}) => {
    if (!order){
      return {
        shipments: [],
        cart_items: cart_item_selectors.getAllCartItems(state)
      };
    }
    const cart_items = findCartItems(state, cart_item_selectors.getAllCartItemIds(state));
    const suppliers = findSuppliers(state, supplier_selectors.currentSupplierIds(state));
    const selected_delivery_methods = supplier_selectors.selectedDeliveryMethods(state);
    return {
      shipments: order_helpers.getOrderShipments(order, cart_items, suppliers, selected_delivery_methods),
      cart_items: cart_item_selectors.getAllCartItems(state)
    };
  };
};

const ShipmentListDTP = {
  trackEvent: analytics_actions.track
};

export const ShipmentListContainer = connect(ShipmentListSTP, ShipmentListDTP)(ShipmentList);

export default connectToObservables(ShipmentListContainer, {order: orderStream});
