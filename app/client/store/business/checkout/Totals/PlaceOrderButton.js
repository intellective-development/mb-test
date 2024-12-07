import { css } from '@amory/style/umd/style';
import React, { useEffect } from 'react';
import { useSelector } from 'react-redux';
import { selectOrderReady, FinalizeOrderProcedure, selectOrderData, selectOrderFetching, selectOrderFinalizing } from 'modules/checkout/checkout.dux';
import styles from '../Checkout.css.json';
import { trackCheckoutStep } from '../../analytics/legacy_tracking_code';

export default () => {
  const isReady = useSelector(selectOrderReady);
  const orderData = useSelector(selectOrderData);
  const orderLoading = useSelector(selectOrderFetching);
  const orderFinalizing = useSelector(selectOrderFinalizing);

  useEffect(() => {
    if (isReady){
      trackCheckoutStep({ step_name: 'confirmation', option: '' });
    }
  }, [isReady]);

  if (!isReady) return null;

  return (
    <button
      className={css(styles.action)}
      disabled={!isReady || orderFinalizing || orderLoading}
      onClick={() => {
        FinalizeOrderProcedure(orderData);
      }}
      type="button">
      { orderFinalizing ? 'Placing the order...' : 'Place Order' }
    </button>
  );
};
