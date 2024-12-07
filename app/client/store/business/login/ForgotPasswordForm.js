import { css } from '@amory/style/umd/style';
import { Form, Field } from 'react-final-form';
import { FORM_ERROR } from 'final-form';
import React from 'react';

import checkoutStyles from 'store/business/checkout/Checkout.css.json';
import fonts from 'store/business/checkout/shared/MBElements/MBFonts.css.json';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';
import unstyle from 'store/business/checkout/shared/MBElements/MBUnstyle.css.json';

import { ResetUserPassword } from 'modules/user/user.dux';

export const ForgotPasswordForm = () => (
  <Form
    onSubmit={form =>
      ResetUserPassword(form)
        .then(({ result: { success } }) => success)
        .catch(({ error }) => ({ [FORM_ERROR]: error.message }))
    }
    // validate={validate}
    render={({ handleSubmit, submitting, submitError, submitSucceeded }) => {
      return (
        <form onSubmit={handleSubmit}>
          <div className={css(styles.b)}>
            <div className={css([unstyle.h, styles.c])}>Forgot your password?</div>
            <Field required autoFocus name="email" component="input" className={css([unstyle.input, fonts.common, styles.d])} placeholder="Email Address" />
            <div className={css([styles.g, checkoutStyles.error])}>{!submitting && submitError}</div>
            <div className={css([styles.g, checkoutStyles.success])}>{!submitting && submitSucceeded && 'Check your email address to finalize resetting your password.'}</div>
            <button className={css([unstyle.button, styles.e, styles.f])} disabled={submitting} type="submit">
              {submitting ? 'Please wait...' : 'Reset Password'}
            </button>
            <a className={css([unstyle.a, styles.g, styles.i])} href="/login">
              Login now
            </a>
          </div>
        </form>
      );
    }} />
);

ForgotPasswordForm.displayName = 'ForgotPasswordForm';
export default ForgotPasswordForm;
