import { css } from '@amory/style/umd/style';
import { Form, Field } from 'react-final-form';
import React from 'react';

import checkoutStyles from 'store/business/checkout/Checkout.css.json';
import fonts from 'store/business/checkout/shared/MBElements/MBFonts.css.json';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';
import unstyle from 'store/business/checkout/shared/MBElements/MBUnstyle.css.json';

import { signupWithCookies } from 'modules/user/user.dux';

import { handleSubmitWithCaptcha, addGoogleReCaptchaScript } from './RecaptchaV3';

export const SignupForm = () => {
  addGoogleReCaptchaScript();
  return (
    <Form
      onSubmit={handleSubmitWithCaptcha(signupWithCookies, 'signup')}
      // validate={validate}
      render={({ handleSubmit, submitting, submitErrors }) => {
        const invalidStyling = css([checkoutStyles.error, checkoutStyles.error__floating_nolabel]);
        return (
          <form onSubmit={handleSubmit}>
            <div className={css(styles.b)}>
              <h1 className={css([unstyle.h, styles.c])}>Create an account</h1>
              <Field
                required
                autoFocus
                name="first_name"
                component="input"
                className={css([unstyle.input, fonts.common, styles.d])}
                autoComplete="given-name"
                placeholder="First Name" />
              <div className={invalidStyling}>{!submitting && submitErrors && submitErrors.first_name}</div>
              <Field required name="last_name" component="input" className={css([unstyle.input, fonts.common, styles.d])} autoComplete="family-name" placeholder="Last Name" />
              <div className={invalidStyling}>{!submitting && submitErrors && submitErrors.last_name}</div>
              <Field required name="email" component="input" className={css([unstyle.input, fonts.common, styles.d])} autoComplete="email" placeholder="Email Address" />
              <div className={invalidStyling}>{!submitting && submitErrors && submitErrors.email}</div>
              <Field
                required
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
                autoComplete="new-password"
                placeholder="Password" />
              <div className={invalidStyling}>{!submitting && submitErrors && submitErrors.password}</div>
              <Field
                required
                name="password_confirmation"
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
                autoComplete="new-password"
                placeholder="Password Confirmation" />
              <div className={invalidStyling}>{!submitting && submitErrors && submitErrors.password_confirmation}</div>
              <button className={css([unstyle.button, styles.e, styles.f])} disabled={submitting} type="submit">
                {submitting ? 'Please wait...' : 'Create Account'}
              </button>
            </div>
          </form>
        );
      }} />
  );
};

SignupForm.displayName = 'SignupForm';
export default SignupForm;
