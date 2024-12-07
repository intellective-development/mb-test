// @flow

import * as React from 'react';
import type { Address } from 'store/business/address';

import AgeTermsWarning from '../../../compounds/AgeTermsWarning';
import AddressEntry from '../../../compounds/AddressEntry';
import GiftPrompt from '../../../compounds/GiftPrompt';
import { MBText, MBModal } from '../../../elements';
import styles from './index.scss';

type AddressPageProps = {
  current_address: Address,
  submitAddress: (Address, () => void, () => void) => void,
  hideModal: () => void
};
const AddressPage = ({current_address, submitAddress, hideModal}: AddressPageProps) => {
  return (
    <div>
      {/* TODO: div -> fragment */}
      <MBModal.SectionHeader
        renderRight={() => <MBModal.Close onClick={hideModal} />} >
        Delivery Address
      </MBModal.SectionHeader>
      <div className={styles.snDeliveryInfoExternal_Body}>
        <MBText.H4 className={styles.snDeliveryInfoExternal_Heading}>
          Minibar Delivery partners with local stores to provide you with the best selection and service
        </MBText.H4>
        <MBText.H5 className={styles.snDeliveryInfoExternal_Subheading}>
          Enter your address to start shopping
        </MBText.H5>
        <GiftPrompt />
        <AddressEntry submitAddress={submitAddress} current_address={current_address} />
        <AgeTermsWarning />
      </div>
    </div>
  );
};

export default AddressPage;
