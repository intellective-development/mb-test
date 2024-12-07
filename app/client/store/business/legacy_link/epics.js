// @flow

import Rx from 'rxjs';

// this epic's purpose is its side effect - it updates the store$ stream so non-redux code can subscribe to it and
// see the actions and state that are coming through
export const store$ = new Rx.ReplaySubject(1);
export const subscribeToBackbone = (action$: Observable<Object>, store: Object) => {
  action$.subscribe(action => {
    store$.next({action, state: store.getState()});
  });
  return action$.filter(() => false); // force the epic to never return anything
};

export default {
  subscribeToBackbone
};
