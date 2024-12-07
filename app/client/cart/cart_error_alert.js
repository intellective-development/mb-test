// @flow

import _ from 'lodash';
import * as React from 'react';

import AlertBox from 'shared/components/alert_box';

// TODO: handle errors in business layer with epic and error rails on add/update_quantity
// then re-assess the UI representation here. Should be dealt with wherever addToCart is allowed
const OUT_OF_STOCK_WARNING = 'Sorry, you cannot add more of this item to your cart.';

type CartErrorAlertProps = {error: string, clearCartError: () => void};
const CartErrorAlert = ({error, clearCartError}: CartErrorAlertProps) => (
  <AlertBox
    show={!_.isEmpty(error)}
    onHide={clearCartError}
    message={OUT_OF_STOCK_WARNING}
    title="Out of Stock" />
);

export default CartErrorAlert;
