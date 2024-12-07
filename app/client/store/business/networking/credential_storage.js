// @flow
import type {
  TokenData,
  UserCredentials,
  CredentialStorage
} from '@minibar/store-business/src/networking/constants';
import { config } from 'store/business/session';

// This module provides a storage mechanism for our authentication data, to enable us to make authorized requests without redundant token requests.
// It stores the data in js objects instead of using a browser storage api because:
//   1. On web we rely on the rails session to manage user authentication. If we were to store auth data on the client,
//      it could easily get out of sync with the session, with unfortunate results.
//   2. In the case of user credentials, the data is sensitive and should not be placed raw in any long term storage.

export const buildCredentialStorage = (initial_token_data: TokenData = null): CredentialStorage => { // exported for testing
  let token_data: TokenData = initial_token_data;
  const getToken = () => {
    if (token_data && token_data.token_type && token_data.access_token){
      return Promise.resolve(token_data);
    } else {
      return Promise.resolve(null);
    }
  };
  const setToken = (next_token_data: TokenData) => {
    token_data = next_token_data;
    return Promise.resolve(true);
  };
  const resetToken = () => {
    token_data = null;
    return Promise.resolve(true);
  };


  let user_credentials: ?UserCredentials = null;
  const getUserCredentials = () => {
    if (user_credentials && user_credentials.email && user_credentials.password){
      return Promise.resolve(user_credentials);
    } else {
      return Promise.resolve(null);
    }
  };
  const setUserCredentials = (next_user_credentials: UserCredentials) => {
    user_credentials = next_user_credentials;
    return Promise.resolve(true);
  };
  const resetUserCredentials = () => {
    user_credentials = null;
    return Promise.resolve(true);
  };

  const resetTokenAndUserCredentials = () => {
    user_credentials = null;
    token_data = null;
    return Promise.resolve(true);
  };

  return {
    getToken,
    setToken,
    resetToken,
    getUserCredentials,
    setUserCredentials,
    resetUserCredentials,
    resetTokenAndUserCredentials
  };
};

const bootstrapped_token_data = {
  access_token: config.initial_access_token,
  token_type: 'bearer'
};
export default buildCredentialStorage(bootstrapped_token_data);
