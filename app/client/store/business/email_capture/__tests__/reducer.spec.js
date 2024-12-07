import { makeSuccessAction, makeErrorAction } from '@minibar/store-business/src/utils/create_actions_for_request';
import * as email_capture_actions from '../actions';

import emailCaptureReducer, {
  isShowingModalReducer,
  shouldShowModalReducer,
  isLoadingReducer,
  emailSubmitErrorReducer,
  modalStatusReducer
} from '../reducer';

describe('emailCaptureReducer', () => {
  it('structures the state slice', () => {
    expect(Object.keys(emailCaptureReducer(undefined, {}))).toEqual([
      'should_show_modal',
      'is_showing_modal',
      'loading',
      'status',
      'error'
    ]);
  });
});

describe('shouldShowModalReducer', () => {
  it('returns the initial state', () => {
    expect(shouldShowModalReducer(undefined, {})).toEqual(true);
  });

  it('handles EMAIL_CAPTURE:SHOULD_SHOW_EMAIL_CAPTURE_MODAL', () => {
    const action = email_capture_actions.shouldShowModal();
    expect(shouldShowModalReducer(false, action)).toEqual(true);
  });

  it('handles EMAIL_CAPTURE:PREVENT_EMAIL_CAPTURE_MODAL', () => {
    const action = email_capture_actions.preventModal();
    expect(shouldShowModalReducer(true, action)).toEqual(false);
  });
});

describe('isShowingModalReducer', () => {
  it('returns the initial state', () => {
    expect(isShowingModalReducer(undefined, {})).toEqual(false);
  });

  it('handles EMAIL_CAPTURE:SHOW_EMAIL_CAPTURE_MODAL', () => {
    const action = email_capture_actions.showModal();
    expect(isShowingModalReducer(false, action)).toEqual(true);
  });

  it('handles UI:HIDE_DELIVERY_INFO_MODAL', () => {
    const action = email_capture_actions.hideModal();
    expect(isShowingModalReducer(true, action)).toEqual(false);
  });
});

describe('isLoadingReducer', () => {
  it('returns the initial state', () => {
    expect(isLoadingReducer(undefined, {})).toEqual(false);
  });

  it('handles EMAIL_CAPTURE:ADD_EMAIL__LOADING', () => {
    const action = {type: 'EMAIL_CAPTURE:ADD_EMAIL__LOADING'};
    expect(isLoadingReducer(false, action)).toEqual(true);
  });

  it('handles EMAIL_CAPTURE:ADD_EMAIL__SUCCESS', () => {
    const action = {type: 'EMAIL_CAPTURE:ADD_EMAIL__SUCCESS'};
    expect(isLoadingReducer(true, action)).toEqual(false);
  });

  it('handles EMAIL_CAPTURE:ADD_EMAIL__ERROR', () => {
    const action = {type: 'EMAIL_CAPTURE:ADD_EMAIL__ERROR'};
    expect(isLoadingReducer(true, action)).toEqual(false);
  });
});

describe('emailSubmitErrorReducer', () => {
  it('returns the initial state', () => {
    expect(emailSubmitErrorReducer(undefined, {})).toEqual('');
  });

  it('handles EMAIL_CAPTURE:SHOW_EMAIL_CAPTURE_MODAL', () => {
    const addEmailError = makeErrorAction('EMAIL_CAPTURE:ADD_EMAIL');
    const action = addEmailError({ error: { message: 'error' } });
    expect(emailSubmitErrorReducer('', action)).toEqual('error');
  });
});

describe('modalStatusReducer', () => {
  it('returns the initial state', () => {
    expect(modalStatusReducer(undefined, {})).toEqual('initial');
  });

  it('handles EMAIL_CAPTURE:ADD_EMAIL__SUCCESS for existing user', () => {
    const addExistingEmailSuccess = makeSuccessAction('EMAIL_CAPTURE:ADD_EMAIL');
    const action = addExistingEmailSuccess({ account_exists: true });
    expect(modalStatusReducer('', action)).toEqual('existing_user');
  });

  it('handles EMAIL_CAPTURE:ADD_EMAIL__SUCCESS for new user', () => {
    const addNewEmailSuccess = makeSuccessAction('EMAIL_CAPTURE:ADD_EMAIL');
    const action = addNewEmailSuccess({ account_exists: false });
    expect(modalStatusReducer('', action)).toEqual('new_user');
  });
});

