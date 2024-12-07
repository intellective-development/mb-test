import React from 'react';
import { get, keys, capitalize, join, uniq, map, compact } from 'lodash';
import { createSelector } from 'reselect';
import Axios from 'axios';
import api_config from '@minibar/store-business/src/networking/api_config';
import createProcedure from 'redux-procedures';
import { fetchUser, resetPassword } from '@minibar/store-business/src/networking/api';
import { selectAddressById } from '../address/address.dux';
import PopupForm from '../../store/business/checkout/CheckoutLogin/PopupForm';
import { addModal, removeModal } from '../../ModalQueue';
import guestAxiosInstance from './guestAxios';
// import { selectAddressById } from '../paymentProfile/paymentProfile.dux';

const localState = ({ user }) => user;

export const selectIsUserLoading = state => localState(state).is_fetching;
export const selectUserId = state => localState(state).current_user_id;
export const selectUserById = state => id => localState(state).by_id[id];

export const selectCurrentUser = createSelector(
  selectUserId,
  selectUserById,
  (current_user_id, userById) => userById(current_user_id)
);

export const selectCurrentUserAddresses = createSelector(
  selectCurrentUser,
  selectAddressById,
  (user, addressById) => compact(map(get(user, 'user.shipping_addresses'), addressById))
);

export const FetchUserProcedure = createProcedure('FETCH_USER', async(payload, meta, store) => {
  // TODO: fetch user with addresses and payment profiles and set it to the store
  return fetchUser().then(result => {
    store.dispatch(({
      type: 'USER:FETCH_USER__SUCCESS',
      payload: result,
      meta
    }));
  });
});

export const ResetUserPassword = createProcedure('RESET_USER_PASSWORD', async(payload) => {
  return resetPassword(payload);
});

export const withCookies = url => form => {
  const csrfParam = document.querySelector('meta[name=csrf-param]').content;
  const csrfToken = document.querySelector('meta[name=csrf-token]').content;
  const csrfField = { remember_me: true };
  csrfField[csrfParam] = csrfToken;

  return Axios({
    url,
    method: 'POST',
    data: {
      ...csrfField,
      registered_account: form
    },
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    withCredentials: true
  })
    .then(response => {
      return api_config.credential_storage
        .setToken({
          token_type: 'bearer',
          access_token: response.headers['x-minibar-access-token']
        });
    });
};

export const loginWithCookies = (args) => withCookies('/users/sign_in')(args)
  .then(FetchUserProcedure)
  .then(result => {
    removeModal('email-already-exists');
    return result;
  })
  .catch(e => Promise.reject(get(e, 'response.data', { error: get(e, 'error.message', 'Unknown error encountered.') })));

export const signupWithCookies = (args) => withCookies('/users')(args)
  .then(FetchUserProcedure)
  .catch(e => {
    const errors = get(e, 'response.data.errors', {});
    const submitErrors = {};
    keys(errors).forEach(key => { submitErrors[encodeURIComponent(key)] = `${capitalize(encodeURIComponent(key).replace(/_/g, ' '))} ${join(uniq(encodeURIComponent(errors[key])), ' and ')}.`; });
    return Promise.reject({submitErrors});
  });

export const guestSignUp = (args) => {
  window.User.set('new_user', undefined);
  window.User.set('new_user_token', '');
  return guestAxiosInstance
    .post('/oauth/token', {
      client_id: global.ClientId,
      client_secret: global.ClientSecret,
      grant_type: 'client_credentials'
    })
    .then(({ data }) => {
      const accessToken = get(data, 'access_token');
      guestAxiosInstance.defaults.headers.common.Authorization = `Bearer ${accessToken}`;
      return guestAxiosInstance.post('/api/v2/user', args);
    })
    .then((response) => {
      window.User.set('new_user', args);
      window.User.set('new_user_token', response.data.user_token);
      return response;
    })
    .catch(e => {
      const errorMessage = get(e, 'response.data.error.message', {});
      if (errorMessage === 'Email address belongs to an existing user.'){
        addModal({
          id: 'email-already-exists',
          contents: <PopupForm email={args.contact_email} />
        });
        const errorObject = { error: { message: undefined }};
        throw errorObject;
      }
      const errorObject = { error: { message: errorMessage } };
      throw errorObject;
    });
  // TODO: call to the register endpoint
  // TODO: store the token
};
