// @flow

import { globalizeSelectors } from '@minibar/store-business/src/utils/globalizeSelectors';
import type { LocalState } from './reducer';

const LOCAL_PATH = 'email_capture';

// selectors
export const shouldShowModal = (state: LocalState) => {
  return state.should_show_modal;
};
export const isModalShowing = (state: LocalState) => {
  return state.is_showing_modal;
};
export const isLoading = (state: LocalState) => {
  return state.loading;
};
export const modalStatus = (state: LocalState) => {
  return state.status;
};
export const error = (state: LocalState) => {
  return state.error;
};

// global selectors
export default {
  ...globalizeSelectors(LOCAL_PATH, {
    shouldShowModal,
    isModalShowing,
    isLoading,
    modalStatus,
    error
  })
};
