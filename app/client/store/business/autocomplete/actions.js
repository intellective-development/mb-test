// @flow

import type { Action } from '@minibar/store-business/src/constants';
import { request_status_utils } from '../request_status';

export const attemptAutocomplete = (query: string): Action => ({
  type: 'AUTOCOMPLETE:ATTEMPT',
  payload: { query }
});

export const updateCurrentQuery = (query: string): Action => ({
  type: 'AUTOCOMPLETE:UPDATE_CURRENT_QUERY',
  payload: { query }
});

export const fetchResults = (query: string): Action => ({
  type: 'AUTOCOMPLETE:FETCH',
  payload: { query },
  meta: {
    action_id: query,
    request_data: request_status_utils.pendingRequestData(query)
  }
});
