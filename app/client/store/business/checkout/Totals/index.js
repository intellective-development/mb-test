import React from 'react';
import { useSelector } from 'react-redux';
import { css } from '@amory/style/umd/style';
import { Link } from 'react-router-dom';
import { useCheckoutOrderEffect } from 'modules/checkout/checkout.hooks';
import { SaveTime } from '../Complete/OrderPanel/SaveTime';
import Panel from '../shared/Panel';
import PanelTitle from '../shared/PanelTitle';
import Row from '../shared/Row';
import SecurePayments from './SecurePayments';
import PromoCode from './PromoCode';
import {
  ShipmentListContainer
} from '../../../views/scenes/CheckoutConfirm/ShipmentList';
import Shipments from './Shipments';
import PlaceOrderButton from './PlaceOrderButton';
import SummaryTable from '../SummaryPanel/SummaryTable';
import styles from '../Checkout.css.json';
import { selectOrderReady } from '../../../../modules/checkout/checkout.dux';

const Totals = () => {
  const {
    orderItems,
    cartReady
  } = useCheckoutOrderEffect();
  const isReady = useSelector(selectOrderReady);

  if (!orderItems.length && cartReady){
    return (
      <Panel
        id="order-summary"
        style={{
          flex: 1,
          alignItems: 'stretch'
        }}>
        <div className={css(styles.header)}>
          <PanelTitle id="summary">
            No items in your cart.
          </PanelTitle>
          <Row>
            <Link to="/store" className={css([{ fontWeight: 'bold' }])}>Shop more</Link>
          </Row>
        </div>
      </Panel>
    );
  }

  return (
    <React.Fragment>
      <Panel
        id="order-summary"
        style={{
          flex: 1,
          alignItems: 'stretch'
        }}>
        <Row>
          <div>
            <p className={css([styles.p, styles.totalsp])}>
              If a person over 21 is not available to receive this order, it will be returned for a $20 restocking fee. Valid Government ID required.
            </p>
          </div>
        </Row>

        <Row style={styles.hideOnMobile}>
          <PlaceOrderButton />
        </Row>

        <Row style={{ ...styles.hideOnMobile, justifyContent: 'center' }}>
          <SecurePayments />
        </Row>

        <Row style={styles.hideOnMobile}>
          <PromoCode />
        </Row>

        <Row style={{ ...styles.hideOnMobile, display: 'block' }}>
          <ShipmentListContainer />
        </Row>

        <Row style={{ ...styles.hideOnMobile, margin: 5 }}>
          <SummaryTable />
        </Row>

        <Row style={{ ...styles.hideOnMobile, display: 'block' }}>
          <Shipments />
        </Row>

        {/* No longer in the specs of TECH-1529
        <Row>
          <div>
            <p className={css([styles.p, styles.totalsp])}>
              You’ll receive a confirmation email after placing the order.
            </p>
            <p className={css([styles.p, styles.totalsp])}>
              If a person over 21 is not available to receive this order,
              it will be returned for a $20 restocking fee.
            </p>
            <p className={css([styles.p, styles.totalsp])}>
              Valid Government ID required.
            </p>
            <p className={css([styles.p, styles.totalsp])}>
              If you have any problems, you can contact us at <strong>(855) 487-0740</strong>.
            </p>
          </div>
        </Row>
        */}

        { isReady && <Row>
          <SaveTime postCheckout={false} />
        </Row> }

        <Row>
          <PlaceOrderButton />
        </Row>

        <Row
          style={{
            justifyContent: 'center',
            margin: 5
          }}>
          <SecurePayments />
        </Row>
      </Panel>
    </React.Fragment>
  );
};

export default Totals;
