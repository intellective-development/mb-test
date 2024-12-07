import { css } from '@amory/style/umd/style';
import React from 'react';
import { Redirect } from 'react-router-dom';
import { useSelector } from 'react-redux';

import fonts from 'store/business/checkout/shared/MBElements/MBFonts.css.json';
import unstyle from 'store/business/checkout/shared/MBElements/MBUnstyle.css.json';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';

import { selectCurrentUser } from 'modules/user/user.dux';

import SignupForm from './SignupForm';

export const Signup = () => {
  const user = useSelector(selectCurrentUser);
  if (user) return <Redirect to="/store" />;

  return (
    <div className={css([fonts.common, styles.a])}>
      <SignupForm />

      <div className={css(styles.b)}>
        <div className={css(styles.c)}>Are you already a member?</div>
        <a href="/login" className={css([unstyle.button, styles.e, styles.h])}>
          Login now
        </a>
      </div>
    </div>
  );
};

Signup.displayName = 'Signup';
export default Signup;
