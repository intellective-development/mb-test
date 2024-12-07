//@flow
import React, { Fragment, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { css } from '@amory/style/umd/style';
import { Field, Form } from 'react-final-form';
import { SavePickupDetailsProcedure, selectIsUserGuest, selectPickupDetails } from 'modules/checkout/checkout.dux';
import { required } from 'modules/utils';
import useDeliveryAddressForm from '../DeliveryAddressFormHook';
import { Input, Checkbox } from '../../shared/elements';
import { formatPhone } from '../../shared/format-phone';
import Panel from '../../shared/Panel';
import PanelTitle from '../../shared/PanelTitle';
import Row from '../../shared/Row';

import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from '../../Checkout.css.json';
import { trackCheckoutStep } from '../../../analytics/legacy_tracking_code';
import { useTrackScreenEffect } from '../../../analytics/hooks';

const requiredPhoneNumber = value => required(value) && 'Phone number is required';
const requiredFirstName = value => required(value) && 'First name is required';
const requiredLastName = value => required(value) && 'Last name is required';
const requiredEmail = value => required(value) && 'Email is required';

const parsePhone = value => value.replace(/\D/g, '');

const DeliveryAddressForm = () => {
  const {
    first_name,
    last_name
  } = useDeliveryAddressForm();
  useEffect(() => {
    trackCheckoutStep({ step_name: 'pickup_detail', option: 'new' });
  }, []);
  useTrackScreenEffect('checkout_pickup_detail');
  const isGuest = useSelector(selectIsUserGuest);
  const pickup = useSelector(selectPickupDetails);
  // TODO: maybe move it to the hook?
  const initialValues = {
    first_name,
    last_name,
    ...pickup
  };

  return (
    <Form
      onSubmit={SavePickupDetailsProcedure}
      keepDirtyOnReinitialize
      initialValues={initialValues}
      render={({ form, handleSubmit, submitting, invalid }) => {
        return (
          <Fragment>
            <Panel id="delivery-address">
              <form
                className={css(styles.form)}
                id="checkout-confirm-delivery"
                noValidate="novalidate"
                onSubmit={handleSubmit}>
                <div className={css(styles.header)}>
                  <PanelTitle id="pickup-details">
                    Pickup Details
                  </PanelTitle>
                </div>

                <Row>
                  <div
                    className={css({ display: 'inline-block' })}>
                    <Field
                      component={Checkbox}
                      defaultChecked={false}
                      id="isGift"
                      name="isGift"
                      type="checkbox" />
                  </div>
                  <label
                    className={css(styles.giftLabel)}
                    htmlFor="isGift">
                    Gift wrapped (free).
                  </label>
                </Row>

                <Row>
                  <Field
                    component={Input}
                    id="pickup-phone-number"
                    isRequired
                    label="Phone"
                    name="phone"
                    placeholder="555-555-5555"
                    size={27}
                    format={formatPhone}
                    parse={parsePhone}
                    type="tel"
                    validate={requiredPhoneNumber} />
                </Row>

                { isGuest ? <Row>
                  <Field
                    component={Input}
                    id="delivery-address-send-email-address"
                    isRequired
                    label="Email"
                    name="email"
                    placeholder="msmith@example.com"
                    size={27}
                    type="email"
                    validate={requiredEmail} />
                </Row> : null }

                <Row>
                  <Field
                    component={Input}
                    id="delivery-address-send-first-name"
                    isRequired
                    label="First Name"
                    name="first_name"
                    placeholder="Mary"
                    size={63}
                    type="text"
                    validate={requiredFirstName} />
                  <Field
                    component={Input}
                    id="delivery-address-send-last-name"
                    isRequired
                    label="Last Name"
                    name="last_name"
                    placeholder="Smith"
                    size={63}
                    type="text"
                    validate={requiredLastName} />
                </Row>

                <Row>
                  <button
                    action="submit"
                    disabled={invalid || submitting}
                    className={css([
                      unstyle.button,
                      styles.action
                    ])}
                    id="button-update-address"
                    type="submit">
                    {submitting ? 'Saving...' : 'Save'}
                  </button>
                </Row>
              </form>
            </Panel>
          </Fragment>
        );
      }} />
  );
};

export default DeliveryAddressForm;
