import { css } from '@amory/style/umd/style';
import React, { Fragment, useState } from 'react';
import { useSelector } from 'react-redux';
import {
  selectCurrentDeliveryAddress
} from 'modules/address/address.dux';
import {
  selectCheckoutOrder
} from 'modules/checkout/checkout.selectors';
import {
  CreateOrderProcedure
} from 'modules/checkout/checkout.procedures';
import { Input } from '../shared/elements';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';
import cartDropdownStyles from '../../../views/compounds/Navigation/DesktopNavigation/CartInfo/CartDropdown.scss';

export const PromoCode = () => {
  const order = useSelector(selectCheckoutOrder) || {};
  const [promoCode, setPromoCode] = useState(order.promo_code || '');
  const address = useSelector(selectCurrentDeliveryAddress);
  const acceptingPromoCode = !!address || !!order.shipping_address; // to ensure address-based conditions work reliably

  const updatePromoCode = () => CreateOrderProcedure({
    number: order.number,
    promo_address: address,
    promo_code: promoCode
  }).catch(() => setPromoCode(''));
  const clearPromoCode = () => CreateOrderProcedure({
    number: order.number,
    promo_code: 'REMOVE_PROMO_CODE'
  }).catch(() => setPromoCode(''));

  const PromoCodeSection = () => {
    if (order.promoCodeError){
      return (<span className={css([styles.error])}>{order.promoCodeError}</span>);
    }
    if (order.promo_code){
      return (<span className={css([styles.success])}>Promo Code Applied</span>);
    }
    return null;
  };

  return order.number ? (
    <Fragment>
      <div className={css([styles.promoCodeResult])}>
        <PromoCodeSection />
      </div>
      {/* https://medium.com/paul-jaworski/turning-off-autocomplete-in-chrome-ee3ff8ef0908 */}
      <input
        type="hidden"
        value="autocomplete-disabler" />
      <Input
        id="place-order-promo-code"
        input={{
          onChange: e => setPromoCode(e.nativeEvent.target.value),
          value: promoCode
        }}
        label="Promo Code"
        placeholder={acceptingPromoCode ? 'Enter code…' : 'Waiting for Delivery Information…'}
        disabled={!acceptingPromoCode}
        readOnly={!!order.promo_code}
        size={54}
        type="text" />
      {order.promo_code ? (<div
        role="button"
        tabIndex={0}
        className={cartDropdownStyles.cmCartDropdown_Item_Remove}
        style={{margin: '20px 16px 0px 16px'}}
        disabled={!acceptingPromoCode}
        onClick={clearPromoCode}>
        ×
      </div>) : (<button
        className={css([unstyle.button, styles.promo])}
        disabled={!acceptingPromoCode}
        onClick={updatePromoCode}
        type="button">
        +
      </button>)}
    </Fragment>
  ) : null;
};

PromoCode.displayName = 'PromoCode';

export default PromoCode;
