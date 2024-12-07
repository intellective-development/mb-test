import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import styles from './OrderPanel.css.json';

export const OrderPlaced = ({ orderNum }) => (
  <div className={css([fonts.common, styles.a])}>
    <div className={css(styles.b)}>Order Placed</div>
    <div className={css(styles.c)}>Thank you for your order &mdash; your order number is {orderNum}. You&lsquo;ll receive an email confirmation shortly.</div>
  </div>
);

OrderPlaced.displayName = 'OrderPlaced';

OrderPlaced.propTypes = {
  orderNum: PropTypes.number
};

export default OrderPlaced;
