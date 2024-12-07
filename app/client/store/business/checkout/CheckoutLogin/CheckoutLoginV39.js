import { css } from '@amory/style';
import PropTypes from 'prop-types';
import React from 'react';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from './CheckoutLogin.css.json';

export const CheckoutLoginV39 = ({ email }) =>
  (
    <div className={css([fonts.common, styles.a])}>
      <div>
        <div className={css([styles.g, styles.j])}>
          It seems that you already have an account
          {' '}
          <strong>{email}</strong>
          . Please login to finalize the order using that email address.
        </div>
        <input
          className={css([unstyle.input, styles.d])}
          defaultValue={email}
          placeholder="Email Address" />
        <button
          className={css([unstyle.button, styles.e, styles.f])}
          type="button">
          Reset Password
        </button>
        <a
          className={css([unstyle.a, styles.g, styles.i])}
          href="/users/password/new">
          Login now
        </a>
      </div>
    </div>
  );

CheckoutLoginV39.displayName = 'CheckoutLoginV39';

CheckoutLoginV39.propTypes = {
  email: PropTypes.string.isRequired
};

export default CheckoutLoginV39;
