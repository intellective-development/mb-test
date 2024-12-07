import { createSelector } from 'reselect';
import { values, filter, orderBy, head } from 'lodash';
import createProcedure from 'redux-procedures';
import * as api from '@minibar/store-business/src/networking/api';
import { selectIsUserGuest } from '../checkout/checkout.dux';
import { guestCallWrapper } from '../user/guestAxios';


const createAddressApi = (address, meta, store) => {
  const isGuest = selectIsUserGuest(store.getState());
  const wrapper = isGuest ? guestCallWrapper : fn => fn;
  return wrapper(api.createShippingAddress)(address, address.local_id)
    .then(payload => {
      if (!isGuest){
        store.dispatch({ type: 'ADDRESS:SAVE_DELIVERY_ADDRESS__SUCCESS', payload, meta: { address_id: address.local_id }});
      }
      return payload;
    });
  // TODO: address is not reduced properly
};

const createPickupApi = (address, meta, store) => {
  const wrapper = selectIsUserGuest(store.getState()) ? guestCallWrapper : fn => fn;
  return wrapper(api.createPickupDetail)(address, address.local_id);
  // TODO: address is not reduced properly
};

const localState = ({ address }) => address;
export const selectAddresses = state => localState(state).by_id;
export const selectAddressById = state => id => localState(state).by_id[id];
export const selectCurrentDeliveryAddressId = state => localState(state).current_delivery_address_id;
export const selectCurrentDeliveryAddress = createSelector(
  selectCurrentDeliveryAddressId,
  selectAddressById,
  (currentId, addressById) => addressById(currentId)
);
export const selectSavedAddresses = state => filter(values(localState(state).by_id), 'id');
export const selectLastSavedAddress = state => head(orderBy(selectSavedAddresses(state), 'id', 'desc'));
export const selectSavedAddressesLikeCurrent = createSelector(
  selectCurrentDeliveryAddress,
  selectSavedAddresses,
  (current, saved) => filter(saved, {
    address1: current.address1,
    address2: current.address2 || null, // current.address2 may be undefined while saved.$.address2 is null
    city: current.city,
    state: current.state,
    zip_code: current.zip_code
  })
);
export const selectLastSavedAddressLikeCurrent = createSelector(selectSavedAddressesLikeCurrent, (saved) => head(orderBy(saved, 'id', 'desc')));

export const CreateAddressProcedure = createProcedure('CREATE_ADDRESS', createAddressApi);
export const CreatePickupProcedure = createProcedure('CREATE_PICKUP', createPickupApi);
