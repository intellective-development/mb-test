import React from 'react';
import { map } from 'lodash';
import { css } from '@amory/style/umd/style';
import { usePaymentProfileList } from 'modules/paymentProfile/hooks';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';
import PaymentProfileItem from './PaymentProfileItem';

const PaymentProfilesList = () => {
  const { paymentProfiles } = usePaymentProfileList();
  return (
    <table
      className={css([
        unstyle.table,
        fonts.common,
        styles.cctable
      ])}>
      <tbody>{map(paymentProfiles, props => <PaymentProfileItem key={props.id} {...props} />)}</tbody>
    </table>
  );
};

export default PaymentProfilesList;
