// @flow
import React, { useState, useRef, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { get } from 'lodash';
import { css } from '@amory/style/umd/style';
import { Field, Form } from 'react-final-form';
import { Braintree, HostedField } from 'react-braintree-fields';
import { required } from 'modules/utils';
import { usePaymentProfileForm } from 'modules/paymentProfile/hooks';
import {
  SavePaymentInfoProcedure,
  selectCheckoutAddress,
  selectShippingOptions
} from 'modules/checkout/checkout.dux';
import { selectCurrentUser } from 'modules/user/user.dux';
import { Input, Checkbox, Labeled } from '../shared/elements';
import Row from '../shared/Row';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';
import SecurePayments from '../Totals/SecurePayments';
import { trackCheckoutStep } from '../../analytics/legacy_tracking_code';
import { useTrackScreenEffect } from '../../analytics/hooks';


const AddCardForm = () => {
  const token = useRef(null);
  const ccNum = useRef(null);
  const [isBraintreeReady, setBraintreeReady] = useState(false);
  const [fields, setFields] = useState(false);
  const checkoutAddress = useSelector(selectCheckoutAddress);
  const {
    hasShipping,
    hasPickup
  } = useSelector(selectShippingOptions);
  const address = {
    name: get(checkoutAddress, 'name'),
    city: get(checkoutAddress, 'city'),
    state: get(checkoutAddress, 'state'),
    address1: get(checkoutAddress, 'address1'),
    address2: get(checkoutAddress, 'address2'),
    zip_code: get(checkoutAddress, 'zip_code')
  };
  useEffect(() => {
    trackCheckoutStep({ step_name: 'add_payment', option: 'new' });
  }, []);
  useTrackScreenEffect('checkout_add_payment');
  const {
    tokenizationKey
  } = usePaymentProfileForm();
  const user = useSelector(selectCurrentUser) || window.User.get('new_user');
  const name = user && user.first_name !== 'Guest' && user.last_name !== 'Account' ? `${user.first_name} ${user.last_name}` : '';
  const onlyPickup = hasPickup && !hasShipping;

  if (!tokenizationKey){
    return (
      <Row>Securing payment channel...</Row>
    );
  }

  const submit = async formValues => {
    const form = formValues.same_as_shipping ? { ...formValues, address: { ...formValues.address, ...checkoutAddress, name: formValues.address.name }} : formValues;
    const { nonce: payment_method_nonce } = await token.current({ name: form.address.name, billingAddress: { postalCode: form.zip_code }});
    return SavePaymentInfoProcedure({
      ...form,
      name: form.address.name,
      payment_method_nonce
    });
  };

  const initialValues = {
    same_as_shipping: !onlyPickup,
    address: {
      ...address,
      name
    }
  };

  return (
    <Form
      onSubmit={submit}
      keepDirtyOnReinitialize
      initialValues={initialValues}
      validate={() => {
        const errors = {};
        if (!get(fields, 'cvv.isValid', false) && !get(fields, 'cvv.isFocused', false)){
          errors.cvv = 'CVV invalid'; // TODO: localize
        }
        if (!get(fields, 'expirationDate.isValid', false) && !get(fields, 'expirationDate.isFocused', false)){
          errors.expirationDate = 'Expiration date invalid'; // TODO: localize
        }
        if (!get(fields, 'number.isValid', false) && !get(fields, 'number.isFocused', false)){
          errors.number = 'Card Number invalid'; // TODO: localize
        }
        return errors;
      }}
      render={({ errors, handleSubmit, invalid, submitting, values }) => {
        const { same_as_shipping } = values;
        return (
          <form
            className={css(styles.form)}
            id="checkout-confirm-delivery"
            noValidate="novalidate"
            onSubmit={handleSubmit}>
            <Row>
              <SecurePayments>By Credit Card:</SecurePayments>
            </Row>
            {
              // TODO: CC and PAYPAL SELECTORS
            }
            <Row>
              <Field
                component={Input}
                id="payment-info-name-on-card"
                isRequired
                validate={required}
                label="Name On Card"
                name="address.name"
                placeholder="John Smith"
                size={63}
                type="text" />
              <Field name="number" component="input" type="hidden" />
              <Field name="expirationDate" component="input" type="hidden" />
              <Field name="cvv" component="input" type="hidden" />
            </Row>
            <Braintree
              authorization={tokenizationKey.client_token}
              className={isBraintreeReady ? '' : 'disabled'}
              getTokenRef={ref => { token.current = ref; }}
              onAuthorizationSuccess={setBraintreeReady.bind(this, true)}
              // onCardTypeChange={this.onCardTypeChange}
              onValidityChange={v => setFields(get(v, 'fields', {}))}
              onFocus={v => setFields(get(v, 'fields', {}))}
              onBlur={v => setFields(get(v, 'fields', {}))}
              onEmpty={v => setFields(get(v, 'fields', {}))}
              onNotEmpty={v => setFields(get(v, 'fields', {}))}
              onError={err => {
                console.error(err); // TODO: handle error?
              }}
              styles={{
                'input': {
                  'font-family': 'Avenir, "Helvetica Neue", Helvetica, Arial, sans-serif',
                  'font-size': '15px'
                },
                '.number.valid': {
                  color: '#12781e'
                }
              }}>
              <div className="fields">
                <Row>
                  <Labeled label="Credit Card Number">
                    {
                      //TODO: icon
                    }
                    <HostedField
                      className="hosted-field"
                      ref={ccNum}
                      type="number" />
                    <div className={css([styles.error, styles.error__floating])}>{
                      fields && fields.number && !fields.number.isEmpty && errors.number
                    }</div>
                  </Labeled>
                </Row>
                <Row>
                  <Labeled label="Expiration Date">
                    <HostedField
                      className="hosted-field"
                      type="expirationDate" />
                    <div className={css([styles.error, styles.error__floating])}>{
                      fields && fields.expirationDate && !fields.expirationDate.isEmpty && errors.expirationDate
                    }</div>
                  </Labeled>
                  <Labeled label="Security Code">
                    <HostedField
                      className="hosted-field"
                      type="cvv" />
                    <div className={css([styles.error, styles.error__floating])}>{
                      fields && fields.cvv && !fields.cvv.isEmpty && errors.cvv
                    }</div>
                  </Labeled>
                </Row>
                {!onlyPickup && <Row>
                  <div className={css({
                    margin: 5
                  })}>
                    <Field
                      component={Checkbox}
                      id="payment-info-bill-ship"
                      name="same_as_shipping"
                      type="checkbox" />
                    <label
                      className={css([
                        styles.label,
                        {
                          display: 'inline-block',
                          marginLeft: 5
                        }
                      ])}
                      htmlFor="payment-info-bill-ship">
                      Billing address is the same as shipping
                    </label>
                  </div>
                </Row>}
              </div>
            </Braintree>
            {
              //TODO: is it possible to reduce it to one line?
            }
            {same_as_shipping
              ? null
              : (
                <div>
                  <Row>
                    <Field
                      component={Input}
                      id="payment-info-bill-address"
                      isRequired
                      validate={required}
                      label="Billing Address"
                      name="address.address1"
                      placeholder="PO Box 123"
                      size={63}
                      type="text" />
                  </Row>
                  <Row>
                    <Field
                      component={Input}
                      id="payment-info-bill-city"
                      isRequired
                      validate={required}
                      label="City"
                      name="address.city"
                      placeholder="New York"
                      size={17}
                      type="text" />
                    <Field
                      component={Input}
                      id="payment-info-bill-state"
                      isRequired
                      validate={required}
                      label="State"
                      name="address.state"
                      placeholder="NY"
                      size={17}
                      type="text" />
                    <Field
                      component={Input}
                      id="payment-info-bill-zipcode"
                      isRequired
                      validate={required}
                      label="ZIP code"
                      name="address.zip_code"
                      placeholder="10035"
                      size={11}
                      type="text" />
                  </Row>
                </div>
              )
            }
            <Row>
              <button
                action="submit"
                disabled={invalid || submitting}
                className={css([
                  unstyle.button,
                  styles.action
                ])}
                id="button-update-payment">
                { submitting ? 'Saving...' : 'Save' }
              </button>
            </Row>
          </form>
        );
      }} />
  );
};

export default AddCardForm;
