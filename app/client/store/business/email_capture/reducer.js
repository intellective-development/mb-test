// @flow

import { combineReducers } from 'redux';
import type { Action } from '@minibar/store-business/src/constants';

export const shouldShowModalReducer = (state: boolean = true, action: Action) => {
  switch (action.type){
    case 'EMAIL_CAPTURE:SHOULD_SHOW_EMAIL_CAPTURE_MODAL':
      return true;
    case 'EMAIL_CAPTURE:SHOW_EMAIL_CAPTURE_MODAL':
    case 'EMAIL_CAPTURE:PREVENT_EMAIL_CAPTURE_MODAL':
      return false;
    default:
      return state;
  }
};

export const isShowingModalReducer = (state: boolean = false, action: Action) => {
  switch (action.type){
    case 'EMAIL_CAPTURE:SHOW_EMAIL_CAPTURE_MODAL':
      return true;
    case 'EMAIL_CAPTURE:HIDE_EMAIL_CAPTURE_MODAL':
      return false;
    default:
      return state;
  }
};

export const isLoadingReducer = (state: boolean = false, action: Action) => {
  switch (action.type){
    case 'EMAIL_CAPTURE:ADD_EMAIL__LOADING':
      return true;
    case 'EMAIL_CAPTURE:ADD_EMAIL__SUCCESS':
    case 'EMAIL_CAPTURE:ADD_EMAIL__ERROR':
      return false;
    default:
      return state;
  }
};

export const emailSubmitErrorReducer = (state: string = '', action: Action) => {
  switch (action.type){
    case 'EMAIL_CAPTURE:ADD_EMAIL__ERROR':
      return action.payload.error.message;
    default:
      return state;
  }
};

type modalStatus = 'initial' | 'exisiting_user' | 'new_user'
export const modalStatusReducer = (state: modalStatus = 'initial', action: Action) => {
  switch (action.type){
    case 'EMAIL_CAPTURE:ADD_EMAIL__SUCCESS':
      return action.payload.account_exists ? 'existing_user' : 'new_user';
    default:
      return state;
  }
};

export type LocalState = {
  should_show_modal: boolean,
  is_showing_modal: boolean,
  loading: boolean,
  status: modalStatus,
  error: string
};

const emailCaptureReducer = combineReducers({
  should_show_modal: shouldShowModalReducer,
  is_showing_modal: isShowingModalReducer,
  loading: isLoadingReducer,
  status: modalStatusReducer,
  error: emailSubmitErrorReducer
});

export default emailCaptureReducer;
