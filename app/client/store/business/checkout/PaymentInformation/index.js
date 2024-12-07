// @flow
import React, { Fragment } from 'react';
import { get } from 'lodash';
import { useSelector } from 'react-redux';
import { css } from '@amory/style/umd/style';
import { usePaymentInformation } from 'modules/checkout/checkout.hooks';
import { selectPaymentProfileIds } from 'modules/paymentProfile/paymentProfile.dux';
import PaymentInformationPanel from './PaymentInformationPanel';
import CardsListModal from './CardsListModal';
import AddCardForm from './AddCardForm';
import Panel from '../shared/Panel';
import PanelTitle from '../shared/PanelTitle';
import EditButton from '../shared/EditButton';
import styles from '../Checkout.css.json';

const PaymentInformation = () => {
  const {
    paymentProfileId,
    isEditing,
    openPaymentProfilesList
  } = usePaymentInformation();
  const paymentProfiles = useSelector(selectPaymentProfileIds);
  const hasPaymentProfiles = !!get(paymentProfiles, 'length');
  return (
    <Fragment>
      <Panel id="payment-info">
        <div className={css(styles.header)}>
          <PanelTitle
            id="payment-info"
            isComplete={!isEditing}>
            Payment Info
          </PanelTitle>
          {hasPaymentProfiles && (
            <EditButton onClick={openPaymentProfilesList}>
              Change Card
            </EditButton>
          )}
        </div>
        {paymentProfileId && !isEditing ? <PaymentInformationPanel /> : <AddCardForm />}
        <CardsListModal />
      </Panel>
    </Fragment>
  );
};

export default PaymentInformation;
