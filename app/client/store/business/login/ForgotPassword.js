import { css } from '@amory/style/umd/style';
import React from 'react';

import fonts from 'store/business/checkout/shared/MBElements/MBFonts.css.json';
import unstyle from 'store/business/checkout/shared/MBElements/MBUnstyle.css.json';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';

import ForgotPasswordForm from './ForgotPasswordForm';

export const ForgotPassword = () => (
  <div className={css([fonts.common, styles.a])}>
    <ForgotPasswordForm />

    <div className={css(styles.b)}>
      <div className={css(styles.c)}>Don&#x27;t have an account?</div>
      <div className={css(styles.g)}>You can create an account to check out faster in the future.</div>
      <a href="/signup" className={css([unstyle.button, styles.e, styles.h])}>
        Create Account
      </a>
    </div>
  </div>
);

ForgotPassword.displayName = 'ForgotPassword';
export default ForgotPassword;
