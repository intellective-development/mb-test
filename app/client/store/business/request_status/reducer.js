// @flow

// re-export, abstracting away the dependency
import requestStatusReducer from '@minibar/store-business/src/request_status/reducer';
import type { LocalState } from '@minibar/store-business/src/request_status/reducer';

export default requestStatusReducer;
export type { LocalState };
