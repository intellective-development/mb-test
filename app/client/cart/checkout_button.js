import PropTypes from 'prop-types';
import * as React from 'react';
import { MBLink } from 'store/views/elements';

const CheckoutButton = ({cartValidToCheckout = true, className = ''}) => (
  cartValidToCheckout ? <ProceedToCheckoutButton className={className} /> : <ContinueShoppingButton className={className} />
);
CheckoutButton.propTypes = {
  cartValidToCheckout: PropTypes.bool,
  className: PropTypes.string
};

const ProceedToCheckoutButton = ({className}) => (
  <MBLink.View id="button-checkout" className={`button expand ${className}`} href="/store/checkout">
    Proceed to Checkout
  </MBLink.View>
);

const ContinueShoppingButton = ({className}) => (
  <MBLink.View id="button-home" className={`button expand hollow ${className}`} href="/store/">
    Continue Shopping
  </MBLink.View>
);

export default CheckoutButton;
