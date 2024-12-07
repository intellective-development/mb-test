// @flow

import { globalizeSelectors } from '@minibar/store-business/src/utils/globalizeSelectors';
import type { LocalState } from './reducer';

const LOCAL_PATH = 'session';

// selectors
export const hasCheckedForSuppliers = (state: LocalState) => {
  return state.has_checked_for_suppliers;
};

// global selectors
export default {
  ...globalizeSelectors(LOCAL_PATH, {
    hasCheckedForSuppliers
  })
};
