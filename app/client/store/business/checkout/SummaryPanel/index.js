import { css } from '@amory/style/umd/style';
import { isEmpty, reduce } from 'lodash';
import React from 'react';
import { useSelector } from 'react-redux';
import {
  selectShipmentsGrouped
} from 'modules/cartItem/cartItem.dux';
import {
  selectCheckoutOrder
} from 'modules/checkout/checkout.dux';
import { toFixed } from 'modules/utils';
import { useToggle } from '../shared/use-toggle';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import icon from '../shared/MBIcon/MBIcon';
import Panel from '../shared/Panel';
import PanelTitle from '../shared/PanelTitle';
import PromoCode from '../Totals/PromoCode';
import Row from '../shared/Row';
import {
  ShipmentListContainer
} from '../../../views/scenes/CheckoutConfirm/ShipmentList';
import Shipments from '../Totals/Shipments';
import SummaryTable from './SummaryTable';
import styles from '../Checkout.css.json';

export const SummaryPanel = () => {
  const [toggle, setToggle] = useToggle(false);

  const order = useSelector(selectCheckoutOrder) || {};
  const shipments = useSelector(selectShipmentsGrouped);

  const qty = reduce(shipments, (total, shipment) =>
    total + reduce(shipment, (subtotal, { quantity }) =>
      subtotal + quantity, 0), 0);

  if (isEmpty(order.amounts)){
    return null;
  }

  const { total } = order.amounts || {};

  return (
    <Panel
      id="summary"
      style={styles.hideOnDesktop}>
      <div className={css(styles.header)}>
        <PanelTitle id="summary">
          Summary
        </PanelTitle>
        <button
          className={css([
            unstyle.button,
            icon({
              name: toggle ? 'arrowDown' : 'arrowUp'
            }),
            styles.paneltoggle
          ])}
          onClick={setToggle} />
      </div>

      <Row
        style={{
          fontSize: 13,
          margin: '0 5px 10px'
        }}>
        <span>{qty} item{qty !== 1 ? 's' : ''}</span>
        <span> | </span>
        <span>Total: $ {toFixed(total, 2)}</span>
      </Row>

      <div
        aria-expanded={toggle}
        aria-hidden={!toggle}
        className={css(toggle ? {} : { display: 'none' })}>

        <ShipmentListContainer />

        <Shipments />

        <Row>
          <PromoCode />
        </Row>

        <Row style={{ margin: 5 }}>
          <SummaryTable />
        </Row>
      </div>
    </Panel>
  );
};

SummaryPanel.displayName = 'SummaryPanel';

export default SummaryPanel;
