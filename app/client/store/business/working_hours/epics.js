// @flow
import createActionsForRequest from '@minibar/store-business/src/utils/create_actions_for_request';
import * as api from './api';

const workingHours = (action$: Object) => {
  const report_response_action$ = action$
    .filter(action => action.type === 'WORKING_HOURS:FETCH')
    .switchMap(action => {
      return createActionsForRequest(api.fetchWorkingHours(), action.type, action.meta);
    });

  return report_response_action$;
};

export default { workingHours };
