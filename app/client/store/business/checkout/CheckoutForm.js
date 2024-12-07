import React from 'react';
import { get } from 'lodash';
import { useSelector } from 'react-redux';
import {
  selectCheckoutAddress,
  selectPaymentInfoForm,
  selectPickupDetails,
  selectShippingOptions
} from 'modules/checkout/checkout.dux';
// import AlertBox from 'shared/components/alert_box';
import Autorefill from './Autorefill';
import DeliveryInformation from './DeliveryInformation';
import PaymentInformation from './PaymentInformation/index';
import SummaryPanel from './SummaryPanel';
import Totals from './Totals';
import PlaceOrderButton from './Totals/PlaceOrderButton';
import SecurePayments from './Totals/SecurePayments';
import Panel from './shared/Panel';
import Row from './shared/Row';
import styles from './Checkout.css.json';


const CheckoutForm = ({ setStep }) => {
  // TODO: replace with order data?
  const address = useSelector(selectCheckoutAddress);
  const pickup = useSelector(selectPickupDetails);
  const {
    hasShipping,
    hasPickup
  } = useSelector(selectShippingOptions);
  const { paymentProfileId } = useSelector(selectPaymentInfoForm) || {};
  // the condition for step 2 is a combination of BOTH:
  // 1. it eithers has valid shipping address (submitted and recorded by API, thus having an id), or it does not require shipping address at all
  // 2. it eithers has valid pickup details (submitted and recorded by API, thus having an id), or it does not require pickup details at all
  // (note, in case the order has multiple suppliers and delivery is chosen for some but ISP is chosen for others, both will be required)
  const step2 = ((get(address, 'id') && get(address, 'phone')) || !hasShipping) && ((get(pickup, 'id') && get(pickup, 'phone')) || !hasPickup);
  const step3 = step2 && paymentProfileId;
  setStep(step3 ? 2 : 1);

  return (
    <React.Fragment>
      <div>
        <Panel
          id="mobile-checkout"
          style={{
            ...styles.hideOnDesktop,
            flex: 1,
            alignItems: 'stretch'
          }}>
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
        <SummaryPanel />
        {<DeliveryInformation />}
        {step2 && <PaymentInformation />}
        {step3 && <Autorefill />}
      </div>
      <Totals />
    </React.Fragment>
  );
};

export default CheckoutForm;
