// @flow
import { Action } from '@minibar/store-business/src/constants';

export const fetchWorkingHours = (): Action => ({
  type: 'WORKING_HOURS:FETCH',
  payload: {},
  meta: {}
});
