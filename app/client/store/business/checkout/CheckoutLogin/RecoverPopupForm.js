import { css } from '@amory/style/umd/style';
import React, { useState } from 'react';
import { Form, Field } from 'react-final-form';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from './CheckoutLogin.css.json';
import checkoutStyles from '../Checkout.css.json';
import { ResetUserPassword } from '../../../../modules/user/user.dux';

const RecoverPopupForm = ({ goToLogin, email }) => {
  const [success, setSuccess] = useState(false);
  if (success){
    return (
      <div className={css([fonts.common, styles.n])}>
        <div className={css(styles.m)}>
          <div className={css(unstyle.h)}>
            It seems that you already have an account <span className={css(styles.l)}>{email}</span>.
            Please login in order to finalize the order using that email address.
          </div>
          <div className={css([unstyle.h, styles.o])}>
            Check your email address to finalize resetting your password.
          </div>
          <button
            type="button"
            onClick={() => goToLogin && goToLogin()}
            className={css([unstyle.button, checkoutStyles.action])}>
            Login now
          </button>
        </div>
      </div>
    );
  }
  return (
    <Form
      initialValues={{email: email}}
      onSubmit={(form) => ResetUserPassword(form)
        .then(result => {
          setSuccess(true);
          return result;
        })}
      // validate={validate}
      render={({ handleSubmit }) => {
        return (
          <form onSubmit={handleSubmit}>
            <div className={css([fonts.common, styles.n])}>
              <div className={css(styles.m)}>
                <div className={css(unstyle.h)}>
                  It seems that you already have an account <span className={css(styles.l)}>{email}</span>.
                  Please login in order to finalize the order using that email address.
                </div>
                <Field
                  name="email"
                  component="input"
                  className={css([unstyle.input, fonts.common, styles.d])}
                  placeholder="Email Address" />
                <button
                  onClick={handleSubmit}
                  className={css([unstyle.button, checkoutStyles.action])}>
                  Reset Password
                </button>
                <button
                  type="button"
                  onClick={() => goToLogin && goToLogin()}
                  className={css([unstyle.button, styles.g, styles.i])}>
                  Login now
                </button>
              </div>
            </div>
          </form>
        );
      }} />
  );
};

RecoverPopupForm.displayName = 'RecoverPopupForm';

export default RecoverPopupForm;
