// @flow

import _ from 'lodash';
import { checkStatus, encodeParams, buildExternalUrl, formatRuntimeErrors } from '@minibar/store-business/src/networking/helpers';
import type {
  AuthAPI,
  ClientCredentials,
  UserCredentials,
  AccountInfo
} from '@minibar/store-business/src/networking/constants';
import I18n from '../../localization';
import { config } from '../session';

/* --- Resource Owner Endpoints --- */
// On web, we tie the resource owner grant to the rails session, to ensure that the two are kept in sync.
// Therefore, we hit the devise controllers and pull the OAuth token information out of the headers, returning the data within
// as if it were the response value to abstract away the session requirement from the rest of the client side app.

const { csrf_token } = config;
const buildSessionAuthUrl = buildExternalUrl(() => `${window.api_server_url}/users`);

const BASE_SESSION_FETCH_OPTIONS = {
  credentials: 'same-origin', //pass cookies, for authentication
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',

    // note that this token will become invalid after it gets used.
    // However, the web store should not be able to use it more than once
    // as only sign-in/sign-up consume it, which are non-repeatable during the runtime of the app.
    'X-CSRF-Token': csrf_token
  }
};

const sign_in_path = 'sign_in';
type SignInBody = UserCredentials;
export const signIn = (body: SignInBody) => {
  const url = buildSessionAuthUrl(sign_in_path);
  const request_prom = fetch(url, {
    ...BASE_SESSION_FETCH_OPTIONS,
    method: 'POST',
    body: encodeParams({registered_account: body})
  });

  return request_prom
    .then(sessionCheckStatus)
    .then(formatSessionResponse)
    .catch(formatRuntimeErrors);
};

const sign_up_path = '';
type SignUpBody = UserCredentials & AccountInfo;
export const signUp = (body: SignUpBody) => {
  const url = buildSessionAuthUrl(sign_up_path);
  const request_prom = fetch(url, {
    ...BASE_SESSION_FETCH_OPTIONS,
    method: 'POST',
    body: encodeParams({registered_account: body})
  });

  return request_prom
    .then(sessionCheckStatus)
    .then(formatSessionResponse)
    .catch(formatRuntimeErrors);
};

// this is based off of checkstatus in shared/networking
const sessionCheckStatus = (response: Object) => {
  if (response.ok) return Promise.resolve(response);

  const error_prom = response
    .json()
    .then(
      (json) => ({message: formatSessionEndpointError(json)}), // json response
      () => ({message: I18n.t('global.json_parse')}) // non-json response
    )
    .then(error => Promise.reject({error, response}));

  return error_prom;
};
type SessionErrorResponse = {errors?: {[string]: string[] }, error?: string};
const formatSessionEndpointError = (response: SessionErrorResponse) => {
  if (_.isString(response.error)) return response.error;
  if (_.isEmpty(response.errors)) return I18n.t('client_entities.networking.session_auth_api.default_auth_error');

  const [attribute, attribute_errors] = Object.entries(response.errors)[0];
  if (_.isEmpty(attribute_errors)) return I18n.t('client_entities.networking.session_auth_api.default_auth_error');

  return _.upperFirst(`${attribute} ${attribute_errors[0]}`);
};

const formatSessionResponse = (response) => ({
  token_type: 'bearer',
  access_token: response.headers.get('X-Minibar-Access-Token')
});

/* --- Client Credentials Endpoint --- */
// Unlike the resource owner logic, we don't need to tie the client credentials data to the rails session.
// Therefore, we use the standard api token endpoint to request the data.

const buildOauthUrl = buildExternalUrl(() => `${window.api_server_url}/api/v2`);
const BASE_OAUTH_FETCH_OPTIONS = {
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  }
};

const client_token_path = 'auth/token';
type FetchClientTokenBody = ClientCredentials;
export const fetchClientToken = (body: FetchClientTokenBody) => {
  const url = buildOauthUrl(client_token_path);
  const request_prom = fetch(url, {
    ...BASE_OAUTH_FETCH_OPTIONS,
    method: 'POST',
    body: JSON.stringify(body)
  });

  return request_prom
    .then(checkStatus)
    .then(response => response.json())
    .catch(formatRuntimeErrors);
};

const session_auth_api: AuthAPI = {
  signIn,
  signUp,
  fetchClientToken
};

export default session_auth_api;
export const __private__ = {
  formatSessionEndpointError
};

