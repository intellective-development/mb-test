import { css } from '@amory/style';
import React from 'react';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from './CheckoutLogin.css.json';

export const CheckoutLoginV310 = ({ email }) =>
  (
    <div className={css([fonts.common, styles.a])}>
      <div>
        <div className={css([styles.g, styles.j])}>
          It seems that you already have an account
          {' '}
          <strong>{email}</strong>
          . Please login to finalize the order using that email address.
        </div>
        <strong className={css([styles.g, styles.j])}>
          Check your email address to finalize resetting your password.
        </strong>
        <button
          className={css([unstyle.button, styles.e, styles.f])}
          type="button">
          Login Now
        </button>
      </div>
    </div>
  );

CheckoutLoginV310.displayName = 'CheckoutLoginV310';

export default CheckoutLoginV310;
