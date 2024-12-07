import { css } from '@amory/style/umd/style';
import React from 'react';
import icon from '../shared/MBIcon/MBIcon';
import styles from '../Checkout.css.json';

export const SecurePayments = ({
  style,
  ...props
}) => (
  <div
    className={css([
      icon({ name: 'secure' }),
      styles.secure,
      style
    ])}
    {...props}>
    100% secure payments
  </div>
);

SecurePayments.defaultProps = {
  style: {}
};

export default SecurePayments;
