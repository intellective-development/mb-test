import React from 'react';
import { css } from '@amory/style/umd/style';
import { usePaymentInformation } from 'modules/checkout/checkout.hooks';
import { usePaymentProfileItem } from 'modules/paymentProfile/hooks';
import Row from '../shared/Row';
import icon from '../shared/MBIcon/MBIcon';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';

const PaymentInformationPanel = () => {
  const {
    paymentProfileId
  } = usePaymentInformation();
  const {
    type,
    number,
    expires,
    network
  } = usePaymentProfileItem(paymentProfileId);
  return (
    <Row style={{
      justifyContent: 'space-between',
      margin: '10px 5px'
    }}>
      <div
        className={css([
          unstyle.td,
          icon({
            name: network,
            style: {
              height: 36,
              width: 36
            }
          })
        ])}
        title={type} />
      <div className={css({ flexGrow: 1, padding: '0 10px' })}>
        {number}
      </div>
      <div>Expires {expires}</div>
    </Row>
  );
};

export default PaymentInformationPanel;
