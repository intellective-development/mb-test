import { css } from '@amory/style/umd/style';
import React from 'react';
import styles from 'store/business/checkout/CheckoutLogin/CheckoutLogin.css.json';
import checkoutStyles from 'store/business/checkout/Checkout.css.json';

export const Flash = ({ flash = [] }) => (
  !!flash.length && (<React.Fragment>
    {flash.map(([type, message]) => (
      <div data-alert className={css([styles.b, checkoutStyles.flash[type]])}>
        {message}
        <a href="" className="close float-right">&times;</a>
      </div>
    ))}
  </React.Fragment>)
);

Flash.displayName = 'Flash';
export default Flash;
