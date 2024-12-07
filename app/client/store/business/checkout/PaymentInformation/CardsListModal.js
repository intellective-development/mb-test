import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { css } from '@amory/style/umd/style';
import { MBModal } from 'store/views/elements';
import { ShowPaymentProfilesListModal, selectPaymentInfoForm, SetPaymentInfoEditing } from 'modules/checkout/checkout.dux';

import styles from '../Checkout.css.json';
import PanelTitle from '../shared/PanelTitle';
import PaymentProfilesList from './PaymentProfilesList';
import { trackCheckoutStep } from '../../analytics/legacy_tracking_code';

const CardsListModal = () => {
  const dispatch = useDispatch();
  const { modalOpen } = useSelector(selectPaymentInfoForm);
  useEffect(() => {
    trackCheckoutStep({ step_name: 'add_payment', option: 'select' });
  }, []);
  return (
    <MBModal.Modal
      onHide={() => dispatch(ShowPaymentProfilesListModal(false))}
      show={modalOpen}
      size="medium">
      <div className={css(styles.header)}>
        <PanelTitle id="change-card">Change Card</PanelTitle>
        <MBModal.Close onClick={() => dispatch(ShowPaymentProfilesListModal(false))} />
      </div>
      <div>
        <PaymentProfilesList />
        <div
          className={css({
            textAlign: 'center'
          })}>
          <button
            onClick={() => {
              dispatch(ShowPaymentProfilesListModal(false));
              dispatch(SetPaymentInfoEditing(true));
            }}>
            Add New
          </button>
        </div>
      </div>
    </MBModal.Modal>
  );
};

export default CardsListModal;
