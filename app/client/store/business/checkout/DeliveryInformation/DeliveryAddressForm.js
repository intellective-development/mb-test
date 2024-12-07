//@flow
import React, { Fragment, useEffect } from 'react';
import { css } from '@amory/style/umd/style';
import { Field, Form } from 'react-final-form';
import { SaveCheckoutAddressProcedure } from 'modules/checkout/checkout.dux';
import { required, validEmail } from 'modules/utils';
import useDeliveryAddressForm from './DeliveryAddressFormHook';
import { Checkbox, Input, Textarea, Labeled } from '../shared/elements';
// import EditButton from '../shared/EditButton'; // No longer in the specs of TECH-1527
import { formatPhone } from '../shared/format-phone';
import Hr from '../shared/Hr';
import Row from '../shared/Row';

import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';
import { useAllShipmentsReady } from '../../../../modules/checkout/checkout.hooks';
import { trackCheckoutStep } from '../../analytics/legacy_tracking_code';
import { useTrackScreenEffect } from '../../analytics/hooks';

const requiredEmail = (value) => {
  if (required(value)) return 'Your email is required';
  if (validEmail(value)) return 'Your email is invalid';
};
const requiredPhoneNumber = (value) => required(value) && 'Your phone number is required';
const requiredBusinessName = (value) => required(value) && 'A business name is required for a business address';
const requiredName = (value) => required(value) && "Recipient's name is required";
const requiredGiftMessage = (value) => required(value) && 'Gift note is required';
const requiredRecepientPhoneNumber = (value) => required(value) && "Recipient's phone number is required";

const parsePhone = (value) => value.replace(/\D/g, '');

const DeliveryAddressForm = () => {
  useEffect(() => {
    trackCheckoutStep({ step_name: 'confirm_address', option: 'new' });
  }, []);
  useTrackScreenEffect('checkout_address');
  const {
    user,
    address,
    phone,
    checkoutAddress,
    formattedAddress
    // fullName
    // openChangeAddressModal // No longer in the specs of TECH-1527
  } = useDeliveryAddressForm();
  const areAllShipmentsReady = useAllShipmentsReady();

  // TODO: maybe move it to the hook?
  const initialValues = {
    // TODO: is the user allowed to edit this data?
    address,
    isBusiness: 'false',
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    phone, // the phone may be from the last order which coincides
    // address2: address2 // apt (flat) - the apt may be from the last order which coincides
    // delivery notes
    formattedAddress,
    ...checkoutAddress
  };

  return (
    <Form
      onSubmit={SaveCheckoutAddressProcedure}
      keepDirtyOnReinitialize
      initialValues={initialValues}
      render={({ form, handleSubmit, submitting, invalid }) => {
        const formState = form.getState();
        const { isBusiness, isGift } = formState.values;

        return (
          <form className={css(styles.form)} id="checkout-confirm-delivery" noValidate="novalidate" onSubmit={handleSubmit}>
            <div className={css(styles.giftWrap)}>
              <div className={css({ display: 'inline-block' })}>
                <Field component={Checkbox} checked={isGift} id="isGift" name="isGift" type="checkbox" />
              </div>
              <label className={css(styles.giftLabel)} htmlFor="isGift">
                Send as gift (free).
              </label>
              &nbsp;
              <span className={css(styles.giftSpan)}>With personalized note &amp; gift receipt.</span>
            </div>

            <Hr />

            <Row>
              <Labeled label="Type of Address" />
              <label htmlFor="address_type_residential" className={css([styles.label, styles.radioLabel])}>
                &nbsp;
                <Field component="input" id="address_type_residential" name="isBusiness" type="radio" value="false" />
                &nbsp;Residential
              </label>
              <label htmlFor="address_type_business" className={css([styles.label, styles.radioLabel])}>
                &nbsp;
                <Field component="input" id="address_type_business" name="isBusiness" type="radio" value="true" />
                &nbsp;Business
              </label>
            </Row>

            {isBusiness === 'false' ? null : (
              <Row>
                <Field
                  autoComplete="organization"
                  component={Input}
                  id="delivery-address-rcpt-business-name"
                  isRequired
                  label="Business Name"
                  name="company"
                  size={63}
                  type="text"
                  validate={requiredBusinessName} />
              </Row>
            )}

            {!isGift && (
              <Fragment>
                <Row>
                  <Field
                    autoComplete="given-name"
                    autoFocus
                    component={Input}
                    id="delivery-address-send-first-name"
                    isRequired
                    label="First Name"
                    name="first_name"
                    placeholder="Mary"
                    size={63}
                    type="text"
                    validate={requiredName} />
                  <Field
                    autoComplete="family-name"
                    component={Input}
                    id="delivery-address-send-last-name"
                    isRequired
                    label="Last Name"
                    name="last_name"
                    placeholder="Smith"
                    size={63}
                    type="text"
                    validate={requiredName} />
                </Row>
                <Row>
                  <Field
                    autoComplete="email"
                    component={Input}
                    id="delivery-address-send-email-address"
                    isRequired
                    label="Email Address"
                    name="email"
                    placeholder="msmith@example.com"
                    size={27}
                    type="email"
                    disabled={user.email}
                    validate={requiredEmail} />
                  <Field
                    autoComplete="tel-national"
                    component={Input}
                    id="delivery-address-send-phone-number"
                    isRequired
                    label="Phone Number"
                    name="phone"
                    format={formatPhone}
                    parse={parsePhone}
                    placeholder="555-555-5555"
                    size={27}
                    type="tel"
                    validate={requiredPhoneNumber} />
                </Row>
              </Fragment>
            )}

            {isGift && (
              <Row>
                <Field
                  component={Input}
                  id="delivery-address-rcpt-full-name"
                  isRequired
                  label="Recipient Name"
                  maxLength="100" // TODO: maxLength
                  name="recipient_name"
                  placeholder="John Smith"
                  size={27}
                  type="text"
                  validate={requiredName} />
                <Field
                  component={Input}
                  id="delivery-address-rcpt-phone-number"
                  isRequired
                  label="Recipient Phone"
                  maxLength="100"
                  format={formatPhone}
                  parse={parsePhone}
                  name="recipient_phone"
                  placeholder="555-555-5555"
                  size={27}
                  type="tel"
                  validate={requiredRecepientPhoneNumber} />
              </Row>
            )}

            <Row>
              <Field
                component={Input}
                id="delivery-address-rcpt-address"
                isRequired
                label="Address, City, State, ZIP"
                name="formattedAddress"
                disabled
                placeholder="123 Bond St, New York, NY 10035"
                size={45}
                type="text" />
              <Field autoComplete="off" component={Input} id="delivery-address-rcpt-apt" label="Apt #" name="address2" placeholder="" size={9} type="text" />
            </Row>

            {/* Change address function is no longer in the specs of TECH-1527
            <Row>
              <EditButton onClick={openChangeAddressModal}>
                Change address
              </EditButton>
            </Row>
            */}

            <Row>
              <Field
                cols={65}
                component={Textarea}
                id="delivery-address-rcpt-delivery-notes"
                label="Delivery Notes"
                name="delivery_notes"
                placeholder="e.g. On arrival, buzz for entry."
                rows={2} />
            </Row>

            {isGift && (
              <Fragment>
                <Hr />
                <Row>
                  <Field
                    autoComplete="email"
                    component={Input}
                    id="delivery-address-send-email-address"
                    isRequired
                    label="Your Email"
                    name="email"
                    placeholder="msmith@example.com"
                    size={27}
                    type="email"
                    disabled={user.email}
                    validate={requiredEmail} />
                  <Field
                    autoComplete="tel-national"
                    component={Input}
                    id="delivery-address-send-phone-number"
                    isRequired
                    label="Your Phone"
                    name="phone"
                    format={formatPhone}
                    parse={parsePhone}
                    placeholder="555-555-5555"
                    size={27}
                    type="tel"
                    validate={requiredPhoneNumber} />
                </Row>
                <Row>
                  <Field
                    cols={65}
                    component={Textarea}
                    validate={requiredGiftMessage}
                    id="delivery-address-rcpt-gift-note"
                    isRequired
                    label="Gift Note"
                    maxLength="200"
                    name="message"
                    placeholder="Enjoy!"
                    rows={2} />
                </Row>
                <Row>
                  <p className={css(styles.p)}>
                    Alcohol deliveries must be received by someone over 21 years of age, they cannot be left in a mailbox. The store may reach out to the gift recipient to
                    co-ordinate delivery if a scheduled delivery time has not been provided. Note: Beer and oversized items may not come gift wrapped.
                  </p>
                </Row>
              </Fragment>
            )}
            <Row>
              <button
                action="submit"
                disabled={submitting || invalid || !areAllShipmentsReady}
                className={css([unstyle.button, styles.action])}
                id="button-update-address"
                type="submit">
                {submitting ? 'Saving...' : 'Continue to payment information'}
              </button>
            </Row>
          </form>
        );
      }} />
  );
};

export default DeliveryAddressForm;
