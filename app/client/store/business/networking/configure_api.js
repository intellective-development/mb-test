// @flow

import api_config from '@minibar/store-business/src/networking/api_config';
import buildAuth from '@minibar/store-business/src/networking/build_auth';
import credential_storage from './credential_storage';
import * as auth_api from './session_auth_api';
import { config } from '../session';

// we do all of the configuration necessary to use to api module in the shared business logic

const client_credentials = {client_id: config.app_client_id, client_secret: config.app_client_secret};

const configureApi = () => {
  api_config.configure({
    getAuth: () => buildAuth(credential_storage, client_credentials, auth_api),
    getBaseUrl: () => `${window.api_server_url}/api/v2`,
    getDefaultHeaders: () => ({
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }),
    credential_storage
  });
};

export default configureApi;
