import { css } from '@amory/style/umd/style';
import React, { useEffect } from 'react';

import { useSelector } from 'react-redux';
// import { selectCheckoutOrder } from 'modules/checkout/checkout.dux';
import { selectCurrentUser } from 'modules/user/user.dux';

import { ContinueShopping } from './Complete/ContinueShopping/ContinueShopping';
import { OrderPanel } from './Complete/OrderPanel/OrderPanel';
import { SharePanel } from './Complete/SharePanel/SharePanel';
import { TryAppPanel } from './Complete/TryAppPanel/TryAppPanel';

import MinibarLogo from './shared/MinibarLogo';
import ProgressBar from './shared/ProgressBar';

import unstyle from './shared/MBElements/MBUnstyle.css.json';
import styles from './Checkout.css.json';
import { trackCheckoutStep } from '../analytics/legacy_tracking_code';
import { useTrackScreenEffect } from '../analytics/hooks';

export default ({ match: { params: { number } } }) => {
  const orderNumber = parseInt(number);
  // const { replenishment = {} } = useSelector(selectCheckoutOrder) || {};
  // const { enabled, interval } = replenishment || {};
  const { referral_code } = useSelector(selectCurrentUser) || {};
  useEffect(() => {
    trackCheckoutStep({ step_name: 'thank_you', option: '' });
  }, []);
  useTrackScreenEffect('checkout_submit');

  return (
    <div className="dark-bg">
      <header className={css([
        styles.pageheader,
        {
          backgroundColor: '#fff',
          borderBottom: '1px solid rgba(0,0,0,.1)'
        }
      ])}>
        <div className={css(styles.logo)}>
          <MinibarLogo />
        </div>
        <hr className={css([unstyle.hr, styles.hr1])} />
        <ProgressBar step={3} />
      </header>
      <div id="checkout-detail" className="row" style={{ marginTop: '1em' }}>
        <OrderPanel orderNum={orderNumber} />
        {referral_code && <SharePanel promoCode={referral_code} />}
        <TryAppPanel />
        <ContinueShopping />
      </div>
    </div>
  );
};
