// @flow

import type { Action } from '@minibar/store-business/src/constants';
import { request_status_utils } from '../request_status';

export const fetchSearchSwitch = (product_list_id: string): Action => ({
  type: 'SEARCH_SWITCH:FETCH',
  meta: {
    product_list_id,
    request_data: request_status_utils.pendingRequestData(product_list_id)
  }
});
