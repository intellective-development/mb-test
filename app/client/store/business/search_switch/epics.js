// @flow

import Rx from 'rxjs';
import * as Ent from '@minibar/store-business/src/utils/ent';
import * as api from '@minibar/store-business/src/networking/api';
import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';
import createActionsForRequest from '@minibar/store-business/src/utils/create_actions_for_request';

import type { Filter } from '../filter';
import { product_list_helpers } from '../product_list';
import { supplier_helpers, supplier_selectors } from '../supplier';

export const fetchSearchSwitchProductGroupings = (action$: Observable<ActionWeaklyTyped>, store: Object) => {
  const findFilter = Ent.find('filter');
  const findList = Ent.find('product_list');
  const findSuppliers = Ent.find('supplier');

  return action$
    .filter((action) => action.type === 'SEARCH_SWITCH:FETCH')
    .mergeMap((action) => {
      const { product_list_id } = action.meta;
      const state = store.getState();

      const filter = findFilter(state, product_list_id);
      if (!searchSwitchForList(filter)) return Rx.Observable.of(null);

      const product_list = findList(state, product_list_id);
      const sort_option = product_list_helpers.getSortOptionById(product_list_helpers.getSortForList(product_list));
      const current_supplier_ids = supplier_selectors.currentSupplierIds(state);
      const alternative_supplier_ids = supplier_helpers.alternativeIds(findSuppliers(state, current_supplier_ids));
      const params = {
        ...filter,
        ...sort_option,
        supplier_ids: alternative_supplier_ids,
        per_page: 1
      };

      return createActionsForRequest(api.fetchProducts(params), action.type, action.meta);
    })

    // filter out any null actions
    .filter(action => !!action);
};

export default {
  fetchSearchSwitchProductGroupings
};

const searchSwitchForList = (filter: Filter) => {
  return filter.list_type !== 'reorder';
};
