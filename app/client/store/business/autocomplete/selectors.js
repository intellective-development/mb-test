// @flow
import { createSelector } from 'reselect';
import { globalizeSelectors } from '@minibar/store-business/src/utils/globalizeSelectors';
import { request_status_constants, request_status_selectors } from '../request_status';
import type { GlobalState } from '../base_reducer';
import type { LocalState } from './reducer';

const LOCAL_PATH = 'autocomplete';

const getRequestStatuses = (state: GlobalState) => request_status_selectors.getRequestStatusesForActionType(state, 'AUTOCOMPLETE:FETCH');
export const isFetching = createSelector(
  getRequestStatuses,
  (autocomplete_statuses) => Object
    .values(autocomplete_statuses)
    .some(status => status === request_status_constants.LOADING_STATUS || status === request_status_constants.PENDING_STATUS)
);

export const isQueryCached = (state: LocalState) => (query: string) => state.by_query[query] !== undefined;
export const getResultsForQuery = (state: LocalState) => (query: string) => state.by_query[query] || [];

const getAllResults = (state: LocalState) => state.by_query;
const getCurrentQuery = (state: LocalState) => state.current_query;
export const getResults = createSelector(
  [getAllResults, getCurrentQuery],
  (all_results, current_query) => all_results[current_query] || []
);

export default {
  isFetching,
  ...globalizeSelectors(LOCAL_PATH, { isQueryCached, getResultsForQuery, getResults })
};
