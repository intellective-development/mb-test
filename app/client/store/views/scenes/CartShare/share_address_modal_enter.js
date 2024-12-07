import * as React from 'react';

import AddressEntry from 'store/views/compounds/AddressEntry';
import AgeTermsWarning from '../../compounds/AgeTermsWarning';
import { MBModal, MBText } from '../../elements';
import './share_address_modal.scss';

const EnterShareAddress = ({current_address = {}, submitAddress}) => {
  return (
    <div>
      <MBModal.SectionHeader>
        Confirm Delivery Address
      </MBModal.SectionHeader>
      <div className="modal-container address-change-container address-change-container--cart-share">
        <MBText.H4 className={'cmShareAddressModal_Heading'}>
          Please confirm the delivery address for this re-order
        </MBText.H4>
        <MBText.H5 className={'cmShareAddressModal_Subheading'}>
          Pricing and availability may vary by address
        </MBText.H5>
        <AddressEntry
          current_address={current_address}
          submitAddress={submitAddress}
          submit_button_text="Confirm" />
        <AgeTermsWarning />
      </div>
    </div>
  );
};

export default EnterShareAddress;
