import { css } from '@amory/style';
import PropTypes from 'prop-types';
import React from 'react';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from './CheckoutLogin.css.json';

export const CheckoutLoginV38 = ({ email }) =>
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
        <input
          className={css([unstyle.input, styles.d])}
          placeholder="Password" />
        <button
          className={css([unstyle.button, styles.e, styles.f])}
          type="button">
          Login Now
        </button>
        <a
          className={css([unstyle.a, styles.g, styles.i])}
          href="/users/password/new">
          Forgot your password?
        </a>
      </div>
    </div>
  );

CheckoutLoginV38.displayName = 'CheckoutLoginV38';

CheckoutLoginV38.propTypes = {
  email: PropTypes.string.isRequired
};

export default CheckoutLoginV38;
