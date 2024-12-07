// @flow

import Rx from 'rxjs';
import * as Ent from '@minibar/store-business/src/utils/ent';
import * as api from '@minibar/store-business/src/networking/api';
import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';
import createActionsForRequest from '@minibar/store-business/src/utils/create_actions_for_request';
import { supplier_selectors, supplier_helpers } from '../supplier';
import * as autocomplete_actions from './actions';
import autocomplete_selectors from './selectors';
import { MINIMUM_QUERY_LENGTH } from './constants';

export const attemptAutocomplete = (action$: Observable<ActionWeaklyTyped>, store: Object) => {
  return action$
    .filter((action) => action.type === 'AUTOCOMPLETE:ATTEMPT')
    .filter(({ payload }) => payload.query.length >= MINIMUM_QUERY_LENGTH)
    .debounceTime(100)
    .mergeMap((action) => {
      const query = action.payload.query;
      const state = store.getState();
      const is_cached = autocomplete_selectors.isQueryCached(state)(query);

      return is_cached
        ? Rx.Observable.of(autocomplete_actions.updateCurrentQuery(query))
        : Rx.Observable.of(autocomplete_actions.fetchResults(query));
    });
};

export const fetchAutocomplete = (action$: Observable<ActionWeaklyTyped>, store: Object) => {
  const findSuppliers = Ent.find('supplier');

  return action$
    .filter((action) => action.type === 'AUTOCOMPLETE:FETCH')
    .mergeMap(({ payload, type, meta }) => {
      const state = store.getState();
      const supplier_request_params = supplier_selectors.getParamsForSupplierRequest(state);
      const alternative_supplier_ids = supplier_helpers.alternativeIds(findSuppliers(state, supplier_request_params.supplier_ids));
      const request_params = {
        query: payload.query,
        alternative_supplier_ids,
        ...supplier_request_params
      };

      return createActionsForRequest(api.fetchAutocomplete(request_params), type, meta);
    });
};

export default {
  attemptAutocomplete,
  fetchAutocomplete
};
