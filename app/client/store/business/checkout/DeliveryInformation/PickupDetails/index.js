import React from 'react';
import { useSelector } from 'react-redux';
import { selectPickupDetails, selectCheckoutAddressEditing } from 'modules/checkout/checkout.dux';
import PickupDetailsForm from './PickupDetailsForm';
import PickupDetailsPanel from './PickupDetailsPanel';

const PickupDetails = () => {
  const pickupDetails = useSelector(selectPickupDetails);
  const isEditing = useSelector(selectCheckoutAddressEditing);

  if (pickupDetails && pickupDetails.id && !isEditing){
    return (
      <PickupDetailsPanel />
    );
  }
  return (
    <PickupDetailsForm />
  );
};

export default PickupDetails;
