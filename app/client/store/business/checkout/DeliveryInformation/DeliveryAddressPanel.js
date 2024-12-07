import React, { Fragment } from 'react';
import { get, isEmpty, compact } from 'lodash';
import { useSelector } from 'react-redux';
import { css } from '@amory/style/umd/style';
import { selectCheckoutAddress } from 'modules/checkout/checkout.selectors';
import { selectCurrentUser } from 'modules/user/user.dux';

import styles from '../Checkout.css.json';

const formatPhone = (value) => {
  if (!value) return value;
  const onlyNums = value.replace(/[^\d]/g, '');
  if (onlyNums.length <= 3){
    return onlyNums;
  }
  if (onlyNums.length <= 7){
    return `(${onlyNums.slice(0, 3)}) ${onlyNums.slice(3, 7)}`;
  }
  return `(${onlyNums.slice(0, 3)}) ${onlyNums.slice(3, 6)}-${onlyNums.slice(6, 10)}`;
};

const DeliveryAddressPanel = () => {
  const { isGift, isBusiness, company, phone, delivery_notes, recipient_phone, recipient_name, message, ...address } = useSelector(selectCheckoutAddress) || {};
  // const order = {};
  const user = useSelector(selectCurrentUser) || window.User.get('new_user');
  const email = get(user, 'contact_email') || get(user, 'email');

  return (
    <div
      className={css({
        padding: '5px 10px 10px'
      })}>
      {!isGift ? (
        <Fragment>
          <div className={css(styles.deliverytitle)}>Your info:</div>
          {/* Note: address.name = recipient name, address.address.name = buyer name) */}
          <div className={css(styles.deliverysummary)}>
            {(address.address && address.address.name ? address.address.name : address.name) || `${address.first_name} ${address.last_name}`}
          </div>
          {isBusiness && <div className={css(styles.deliverysummary)}>{company}</div>}
          <div className={css(styles.deliverysummary)}>{compact([address.address1, address.address2]).join(', ')}</div>
          <div className={css(styles.deliverysummary)}>{compact([address.city, address.state, address.zip_code]).join(', ')}</div>
          <div className={css(styles.deliverysummary)}>{formatPhone(phone)}</div>
          <div className={css(styles.deliverysummary)}>{email}</div>
        </Fragment>
      ) : (
        <Fragment>
          <br />
          <div className={css(styles.deliverytitle)}>Sending a gift to:</div>
          <div className={css(styles.deliverysummary)}>{recipient_name}</div>
          {address.company && <div className={css(styles.deliverysummary)}>{address.company}</div>}
          <div className={css(styles.deliverysummary)}>{compact([address.address1, address.address2]).join(', ')}</div>
          <div className={css(styles.deliverysummary)}>{compact([address.city, address.state, address.zip_code]).join(', ')}</div>
          <div className={css(styles.deliverysummary)}>{recipient_phone}</div>
          {!isEmpty(message) && (
            <Fragment>
              <br />
              <div className={css(styles.deliverytitle)}>Gift Note:</div>
              <div className={css(styles.deliverysummary)}>{message}</div>
            </Fragment>
          )}
        </Fragment>
      )}
      {!isEmpty(delivery_notes) && (
        <Fragment>
          <br />
          <div className={css(styles.deliverytitle)}>Delivery Notes:</div>
          <div className={css(styles.deliverysummary)}>{delivery_notes}</div>
        </Fragment>
      )}
    </div>
  );
};

export default DeliveryAddressPanel;
