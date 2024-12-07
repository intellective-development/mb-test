import { css } from '@amory/style/umd/style';
import React from 'react';
import { useDispatch, useStore } from 'react-redux';
import { Form, Field } from 'react-final-form';
import { FORM_ERROR } from 'final-form';

import fonts from '../shared/MBElements/MBFonts.css.json';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from './CheckoutLogin.css.json';
import checkoutStyles from '../Checkout.css.json';
import { loginWithCookies } from '../../../../modules/user/user.dux';
import { selectCurrentPaymentProfileId } from '../../../../modules/paymentProfile/paymentProfile.dux';
import { ResetCheckoutAddress, SetCheckoutAddressEditing, SetPaymentInfo, SetUserAsGuest } from '../../../../modules/checkout/checkout.dux';
import { findStoreableAddress } from '../../../views/compounds/AddressEntry/utils';
import { selectAddresses, selectCurrentDeliveryAddress } from '../../../../modules/address/address.dux';

const LoginPopupForm = ({ goToResetPassword, email }) => {
  const dispatch = useDispatch();
  const store = useStore();
  return (
    <Form
      onSubmit={(form) => {
        return loginWithCookies(form)
          .then(() => {
            dispatch(SetUserAsGuest(false));
            dispatch(ResetCheckoutAddress());
            const addresses = selectAddresses(store.getState());
            const currentAddress = selectCurrentDeliveryAddress(store.getState());
            const currentPaymentProfileId = selectCurrentPaymentProfileId(store.getState());
            const storeableAddress = findStoreableAddress(currentAddress, addresses);
            dispatch({
              type: 'ADDRESS:SAVE_DELIVERY_ADDRESS__SUCCESS',
              payload: { entities: { address: {} } },
              meta: { address_id: storeableAddress.local_id }
            });
            dispatch(SetPaymentInfo(currentPaymentProfileId || null));
            dispatch(SetCheckoutAddressEditing(false));
          }).catch(_ => {
            return { [FORM_ERROR]: 'Invalid email or password.' };
          });
      }}
      // validate={validate}
      initialValues={{email: email}}
      render={({ handleSubmit, submitting, submitError }) => {
        return (
          <form onSubmit={handleSubmit}>
            <div className={css([fonts.common, styles.n])}>
              <div className={css(styles.m)}>
                <div className={css([unstyle.h, styles.p])}>
                  It seems that you already have an account <span className={css(styles.l)}>{email}</span>.
                  <br />
                  Please login in order to finalize the order using that email address.
                </div>
                <Field
                  name="email"
                  component="input"
                  className={css([unstyle.input, fonts.common, styles.d])}
                  placeholder="Email Address" />
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
                <button
                  onClick={handleSubmit}
                  disabled={submitting}
                  className={css([unstyle.button, checkoutStyles.action])}>
                  {submitting ? 'Logging in, please wait...' : 'Login Now'}
                </button>
                <button
                  type="button"
                  onClick={() => goToResetPassword && goToResetPassword()}
                  className={css([unstyle.button, styles.g, styles.i])}>
                  Forgot your password?
                </button>
              </div>
            </div>
          </form>
        );
      }} />
  );
};

LoginPopupForm.displayName = 'LoginPopupForm';

export default LoginPopupForm;
