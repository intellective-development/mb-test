import { css } from '@amory/style/umd/style';
import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';

import LoginForm from 'store/business/login/LoginForm';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from './CheckoutLogin.css.json';
import { SetUserAsGuest } from '../../../../modules/checkout/checkout.dux';
import { trackCheckoutStep } from '../../analytics/legacy_tracking_code';
import { useTrackScreenEffect } from '../../analytics/hooks';

export const CheckoutLogin = () => {
  const dispatch = useDispatch();
  const setAsGuest = () => dispatch(SetUserAsGuest(true));

  useEffect(() => {
    trackCheckoutStep({ step_name: 'authentication', option: 'log_in' });
  }, []);
  useTrackScreenEffect('checkout_login');

  return (
    <div className={css([fonts.common, styles.a])}>
      <LoginForm />

      <div className={css(styles.b)}>
        <div className={css(styles.c)}>
          New Customer?
        </div>
        <div className={css(styles.g)}>
          You can choose to create an account later to check out faster in the future.
        </div>
        <button
          onClick={setAsGuest}
          className={css([unstyle.button, styles.e, styles.h])}
          type="button">
          Continue as Guest
        </button>
      </div>
    </div>
  );
};

CheckoutLogin.displayName = 'CheckoutLogin';

export default CheckoutLogin;
