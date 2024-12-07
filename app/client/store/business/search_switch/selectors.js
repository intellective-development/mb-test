// @flow

import { request_status_constants, request_status_selectors } from '../request_status';
import type { GlobalState } from '../base_reducer';

export const isSearchSwitchFetching = (state: GlobalState, search_switch_id: string) => {
  const search_switch_status = request_status_selectors.getRequestStatusByAction(state, 'SEARCH_SWITCH:FETCH', search_switch_id);
  return search_switch_status === request_status_constants.LOADING_STATUS;
};

export default {
  isSearchSwitchFetching
};
