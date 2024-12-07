// @flow
import { compact, map, last, get } from 'lodash';
import { createSelector } from 'reselect';
import createProcedure from 'redux-procedures';
import * as api from '@minibar/store-business/src/networking/api';
import { selectIsUserGuest, SetPaymentInfo } from '../checkout/checkout.dux';
import { guestCallWrapper } from '../user/guestAxios';

const createProfileApi = (payment_profile_params, meta, store) => {
  const wrapper = selectIsUserGuest(store.getState()) ? guestCallWrapper : fn => fn;
  return wrapper(api.createPaymentProfile)(payment_profile_params);
};
const deleteProfileApi = (payment_profile_params, meta, store) => {
  const wrapper = selectIsUserGuest(store.getState()) ? guestCallWrapper : fn => fn;
  const { payment_profile } = store.getState();
  return wrapper(api.deletePaymentProfile)(payment_profile_params)
    .then(() => {
      const alternative_profiles = payment_profile.user_payment_profile_ids
        .filter(_ => _ !== payment_profile_params.id)
        .map(id => ({id}));
      store.dispatch({
        type: 'PAYMENT_PROFILE:DELETE_PROFILE',
        meta: { alternative_profiles },
        payload: { profile_id: payment_profile_params.id }
      });
      // TODO: figure out why we have to re-implement @minibar/store-business/src/payment_profile/reducer.js:65 here?
      if (!alternative_profiles.length || !payment_profile.selected_id){
        store.dispatch(SetPaymentInfo(null));
      } else if (payment_profile.selected_id === payment_profile_params.id){
        store.dispatch(SetPaymentInfo(alternative_profiles[0].id));
      }
    });
};

export const CreateProfileProcedure: ({
  name: String,
  address: Object,
  payment_method_nonce: String
}) => Promise<void> = createProcedure('CREATE_PROFILE', (payload, meta, store) => {
  return createProfileApi(payload, meta, store)
    .then(res => {
      const profile = get(res, 'entities.payment_profile', {})[get(res, 'result')];
      store.dispatch(SetPaymentInfo(profile.id));
      store.dispatch({
        type: 'PAYMENT_PROFILE:CREATE_PROFILE__SUCCESS',
        payload: res
      });
    });
});
export const DeleteProfileProcedure = createProcedure('DELETE_PROFILE', deleteProfileApi);
export const SetDefaultProfileProcedure = createProcedure('SET_DEFAULT_PROFILE', createProfileApi);

const localState = ({ payment_profile }) => payment_profile;
export const selectPaymentProfileById = state => localState(state).by_id;
export const selectCurrentPaymentProfileId = state => {
  const _state = localState(state);
  return _state.selected_id || last(_state.user_payment_profile_ids); // TODO: proper current profile management
};
export const selectPaymentProfileIds = state => localState(state).user_payment_profile_ids;
export const selectCurrentPaymentProfile = createSelector(
  selectCurrentPaymentProfileId,
  selectPaymentProfileById,
  (id, paymentProfileById) => paymentProfileById[id]
);
export const selectUserPaymentProfiles = createSelector(
  selectPaymentProfileIds,
  selectPaymentProfileById,
  (ids, paymentProfileById) => compact(map(ids, id => paymentProfileById[id]))
);
