// @flow

import Rx from 'rxjs';
import { omit } from 'lodash';
import { push } from 'connected-react-router';
import * as Ent from '@minibar/store-business/src/utils/ent';
import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';
import { product_list_constants, product_list_helpers } from '../product_list';
import qs from '../../../utils/qs';

export const updateUrlForFilter = (action$: Rx.Observable<ActionWeaklyTyped>, store: Object) => {
  const findFilter = Ent.find('filter');
  const findProductList = Ent.find('product_list');

  const url_update$ = action$
    .filter(action => action.type === 'PRODUCT_LIST:SET_FILTER' || action.type === 'PRODUCT_LIST:SET_SORT')
    .map(action => {
      const state = store.getState();
      const filter = findFilter(state, action.meta.product_list_id);
      const product_list = findProductList(state, action.meta.product_list_id);
      const sort_option_id = product_list_helpers.getSortForList(product_list);
      const param_sort = sort_option_id === product_list_constants.DEFAULT_SORT_OPTION_ID ? undefined : sort_option_id;

      const base_fragment = window.location.pathname;
      const base_url_filter = qs.parse(window.location.search, { ignoreQueryPrefix: true });
      const params = qs.stringify(omit({
        ...base_url_filter,
        ...filter,
        sort: param_sort
      }, ['base', 'hierarchy_category']), { encode: false, arrayFormat: 'brackets' });
      const destination = params ? `${base_fragment}?${params}` : base_fragment;

      return push(`${destination}`);
    });

  return url_update$;
};

export default {
  updateUrlForFilter
};
