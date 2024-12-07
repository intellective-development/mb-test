import { css } from '@amory/style/umd/style';
import { Form, Field } from 'react-final-form';
import React from 'react';

import checkoutStyles from 'store/business/checkout/Checkout.css.json';
import fonts from 'store/business/checkout/shared/MBElements/MBFonts.css.json';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';
import unstyle from 'store/business/checkout/shared/MBElements/MBUnstyle.css.json';

import { loginWithCookies } from 'modules/user/user.dux';

import { handleSubmitWithCaptcha, addGoogleReCaptchaScript } from './RecaptchaV3';

export const LoginForm = () => {
  addGoogleReCaptchaScript();
  return (
    <Form
      onSubmit={handleSubmitWithCaptcha(loginWithCookies, 'login')}
      // validate={validate}
      render={({ handleSubmit, submitting, submitError }) => {
        return (
          <form onSubmit={handleSubmit}>
            <div className={css(styles.b)}>
              <h1 className={css([unstyle.h, styles.c])}>Are you already a member?</h1>
              <Field autoFocus name="email" component="input" className={css([unstyle.input, fonts.common, styles.d])} placeholder="Email Address" />
              <Field name="storefront_id" type="hidden" component="input" className={css([unstyle.input, fonts.common, styles.d])} placeholder="Storefront" defaultValue="1" />
              <Field
                name="password"
                type="password"
                component="input"
                className={css([
                  unstyle.input,
                  {
                    '%loginpassword[type=password]': {
                      ...fonts.common
                    }
                  },
                  styles.k
                ])}
                placeholder="Password" />
              <div className={css([styles.g, checkoutStyles.error])}>{!submitting && submitError}</div>
              <button className={css([unstyle.button, styles.e, styles.f])} disabled={submitting} type="submit">
                {submitting ? 'Please wait...' : 'Login'}
              </button>
              <a className={css([unstyle.a, styles.g, styles.i])} href="/users/password/new">
                Forgot your password?
              </a>
            </div>
          </form>
        );
      }} />
  );
};

LoginForm.displayName = 'LoginForm';
export default LoginForm;
