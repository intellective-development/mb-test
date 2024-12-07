//@flow

import { globalizeSelectors } from '@minibar/store-business/src/utils/globalizeSelectors';
import type { LocalState } from './reducer';

const LOCAL_PATH = 'working_hours';

// local selectors
export const workingHours = (state: LocalState) => state.working_hours;

// global selectors
export default {
  ...globalizeSelectors(LOCAL_PATH, {
    workingHours
  })
};
