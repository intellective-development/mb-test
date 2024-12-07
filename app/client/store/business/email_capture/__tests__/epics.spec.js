/* eslint import/first: 0 */
jest.mock('@minibar/store-business/src/networking/api');

import Rx from 'rxjs';
import { createStore } from 'redux';
import * as api from '@minibar/store-business/src/networking/api';
import * as email_capture_actions from '../actions';
import email_capture_epics from '../epics';
import baseReducer from '../../base_reducer';

const { addEmailToWaitlist } = email_capture_epics;
const { addEmail } = email_capture_actions;

// TODO: make helpers
const createMBStore = (initial_state) => createStore(baseReducer, initial_state);
const flattenToPromise = (stream, action_count = 2) => stream.take(action_count).toArray().toPromise();


describe('addEmailToWaitlist', () => {
  it('returns existing user: true if an existing account email is submitted', () => {
    const stubbed_api_response = {
      success: true,
      existing_user: true
    };

    const add_existing_email_action = addEmail({ email: 'existinguser@minibardelivery.com', target: 'test-screen' });
    api.joinWaitlist.mockReturnValueOnce(Promise.resolve(stubbed_api_response));
    const action$ = Rx.Observable.of(add_existing_email_action);
    const store = createMBStore({});

    expect.hasAssertions();
    return addEmailToWaitlist(action$, store).let(flattenToPromise).then(([_loading_action, response_action]) => {
      expect(response_action).toEqual({
        type: 'EMAIL_CAPTURE:ADD_EMAIL__SUCCESS',
        payload: {
          existing_user: true,
          success: true
        },
        meta: { analytics: { target: 'test-screen' } }
      });
      expect(api.joinWaitlist).toHaveBeenCalledWith({
        email: 'existinguser@minibardelivery.com',
        address: {zip_code: expect.any(String)},
        source: expect.any(String)
      });
    });
  });
  it('returns existing_user: false if a new account email is submitted', () => {
    const stubbed_api_response = {
      success: true,
      existing_user: false
    };

    const add_existing_email_action = addEmail({email: 'newuser@minibardelivery.com', target: 'test-screen' });
    api.joinWaitlist.mockReturnValueOnce(Promise.resolve(stubbed_api_response));
    const action$ = Rx.Observable.of(add_existing_email_action);
    const store = createMBStore({});

    expect.hasAssertions();
    return addEmailToWaitlist(action$, store).let(flattenToPromise).then(([_loading_action, response_action]) => {
      expect(response_action).toEqual({
        type: 'EMAIL_CAPTURE:ADD_EMAIL__SUCCESS',
        payload: {
          existing_user: false,
          success: true
        },
        meta: { analytics: { target: 'test-screen' } }
      });
      expect(api.joinWaitlist).toHaveBeenCalledWith({
        email: 'newuser@minibardelivery.com',
        address: {zip_code: expect.any(String)},
        source: expect.any(String)
      });
    });
  });
});
