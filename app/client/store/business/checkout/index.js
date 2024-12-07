import React, { useState, useEffect } from 'react';
import { css } from '@amory/style/umd/style';
import { useSelector } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { selectCurrentUser } from 'modules/user/user.dux';
import { selectIsUserGuest } from 'modules/checkout/checkout.dux';
import { useCheckoutOrder } from 'modules/checkout/checkout.hooks';
import {
  CheckoutBody,
  CheckoutModal
} from './shared/elements';
import MinibarLogo from './shared/MinibarLogo';
import ProgressBar from './shared/ProgressBar';
import unstyle from './shared/MBElements/MBUnstyle.css.json';
import styles from './Checkout.css.json';
import CheckoutForm from './CheckoutForm';
import LoginForm from './CheckoutLogin/CheckoutLogin';
import { trackCheckoutStep } from '../analytics/legacy_tracking_code';
import { useTrackScreenEffect } from '../analytics/hooks';

const Checkout = () => {
  const [step, setStep] = useState(1);
  const user = useSelector(selectCurrentUser);
  const guest = useSelector(selectIsUserGuest);
  const {
    orderItems,
    cartReady
  } = useCheckoutOrder();

  useEffect(() => {
    trackCheckoutStep({ step_name: 'initiate', option: 'new_user' });
  }, []);
  useTrackScreenEffect('checkout');

  const isCartEmpty = () => !orderItems || !orderItems.length;
  if (cartReady && isCartEmpty()) return (<Redirect to="/store/cart" />);

  return (
    <React.Fragment>
      <header className={css(styles.pageheader)}>
        <div className={css(styles.logo)}>
          <MinibarLogo />
        </div>
        <hr className={css([unstyle.hr, styles.hr1])} />
        <ProgressBar step={step} />
      </header>
      <CheckoutBody>
        { user || guest
          ? <CheckoutForm setStep={setStep} user={user} />
          : <LoginForm />}
      </CheckoutBody>
      <CheckoutModal />
    </React.Fragment>
  );
};

export default Checkout;
