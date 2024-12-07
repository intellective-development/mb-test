// @flow
import { useState, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { get, lowerCase } from 'lodash';
import BraintreeFactory from 'store/business/payment_profile/braintree';
import { SetPaymentInfo } from 'modules/checkout/checkout.actions';
import {
  selectUserPaymentProfiles,
  DeleteProfileProcedure,
  selectPaymentProfileById
} from './paymentProfile.dux';

export const usePaymentProfileForm = (): {
  openPaymentProfilesList: () => {},
  tokenizationKey: Object
} => {
  const [tokenizationKey, setTokenizationKey] = useState(null);
  useEffect(() => { BraintreeFactory.getToken().then(setTokenizationKey); }, []);
  return ({
    tokenizationKey,
    openPaymentProfilesList: () => ({})// dispatch(setPayment)
  });
};

export const usePaymentProfileList = (): {
  paymentProfiles: Array<Object>,
  isLoading: Boolean
} => {
  const paymentProfiles = useSelector(selectUserPaymentProfiles) || [];
  return {
    isLoading: false, // TODO: loading
    paymentProfiles
  };
};

export const getCardType = cc_card_type => {
  switch (cc_card_type){
    case 'Discover':
    case 'MasterCard':
    case 'Visa':
      return lowerCase(cc_card_type);
    case 'American Express':
      return 'amex';
    default:
      return 'default';
  }
};

export const usePaymentProfileItem = (id: Number): {
  onDeleteProfile: () => {},
  onSelectDefaultProfile: () => {},
  id: Number,
  name: String,
  number: String,
  expires: String,
  network: String,
  type: String
} => {
  const {
    address,
    cc_exp_year,
    cc_exp_month,
    cc_last_four,
    cc_card_type
  } = useSelector(selectPaymentProfileById)[id] || {};
  const dispatch = useDispatch();
  return {
    onDeleteProfile: () => DeleteProfileProcedure({ id }),
    onSelectDefaultProfile: () => dispatch(SetPaymentInfo(id)),
    id,
    type: cc_card_type,
    name: get(address, 'name', ''),
    expires: [cc_exp_month, cc_exp_year].join('/'),
    number: ['**** '.repeat(3), cc_last_four].join(' '),
    network: getCardType(cc_card_type)
  };
};
