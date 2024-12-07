// @flow

import * as api from '@minibar/store-business/src/networking/api';
import createActionsForRequest from '@minibar/store-business/src/utils/create_actions_for_request';

export const addEmailToWaitlist = (action$: Observable<Object>) => {
  const add_email_to_waitlist_response_action$ = action$
    .filter(action => action.type === 'EMAIL_CAPTURE:ADD_EMAIL')
    .switchMap(action => {
      return createActionsForRequest(
        api.joinWaitlist({
          email: action.payload.email,
          address: {zip_code: '00000'},
          source: 'newsletter'
        })
        , action.type
        , action.meta
      );
    });

  return add_email_to_waitlist_response_action$;
};

export default { addEmailToWaitlist };
