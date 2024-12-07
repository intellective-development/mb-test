import { css } from '@amory/style/umd/style';
import React from 'react';
import { Redirect, useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';

import fonts from 'store/business/checkout/shared/MBElements/MBFonts.css.json';
import unstyle from 'store/business/checkout/shared/MBElements/MBUnstyle.css.json';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';

import { selectCurrentUser } from 'modules/user/user.dux';

import Flash from './Flash';
import LoginForm from './LoginForm';

export const Login = ({ flash = [] }) => {
  const user = useSelector(selectCurrentUser);
  const location = useLocation();

  if (user){
    return location.pathname.startsWith('/admin')
      ? <Redirect to="/admin" />
      : <Redirect to="/store" />;
  }

  return (
    <div className={css([fonts.common, styles.a])}>
      <Flash flash={flash} />

      <LoginForm />

      <div className={css(styles.b)}>
        <div className={css(styles.c)}>New Customer?</div>
        <div className={css(styles.g)}>You can create an account to check out faster in the future.</div>
        <a href="/signup" className={css([unstyle.button, styles.e, styles.h])}>
          Create Account
        </a>
      </div>
    </div>
  );
};

Login.displayName = 'Login';
export default Login;
