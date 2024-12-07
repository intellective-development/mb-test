
import Rx from 'rxjs';
import { createStore } from 'redux';
import baseReducer from 'store/business/base_reducer';
import filter_factory from 'store/business/filter/__tests__/filter.factory';
import product_list_factory from 'store/business/product_list/__tests__/product_list.factory';

import { product_list_actions } from 'store/business/product_list';

import {
  updateUrlForFilter
} from '../epics';


jest.mock('shared/dispatcher');
jest.mock('legacy_store/router/location_stream');

// TODO: make helpers
const createMBStore = (initial_state) => createStore(baseReducer, initial_state);
const flattenToPromise = (stream, action_count = 1) => stream.take(action_count).toArray().toPromise();

describe('updateUrlForFilter', () => {
  const product_list_id = 'product-list-id';

  it('handles PRODUCT_LIST:SET_FILTER', () => {
    const product_list = product_list_factory.build();
    const filter = filter_factory.build({
      base: 'hierarchy_category',
      hierarchy_category: 'wine',
      hierarchy_type: ['wine-white', 'wine-red'],
      country: ['france']
    });
    const initial_state = {
      ...product_list_factory.stateify(product_list, product_list_id),
      ...filter_factory.stateify(filter, product_list_id)
    };

    const trigger_action = product_list_actions.setFilter(product_list_id, filter);
    const action$ = Rx.Observable.of(trigger_action);

    const store = createMBStore(initial_state);

    // expect.hasAssertions();
    return updateUrlForFilter(action$, store).let(flattenToPromise).then(() => {
      expect(true); // TODO: test that the location changes to '/store/category/wine?hierarchy_type=%5B%22wine-white%22%2C%22wine-red%22%5D&country=%5B%22france%22%5D'
    });
  });


  it('handles PRODUCT_LIST:SET_SORT', () => {
    const product_list = product_list_factory.build({sort: 'price_asc'});
    const filter = filter_factory.build({
      base: 'hierarchy_category',
      hierarchy_category: 'wine'
    });
    const initial_state = {
      ...product_list_factory.stateify(product_list, product_list_id),
      ...filter_factory.stateify(filter, product_list_id)
    };

    const trigger_action = product_list_actions.setSort(product_list_id, 'price_asc');
    const action$ = Rx.Observable.of(trigger_action);

    const store = createMBStore(initial_state);

    // expect.hasAssertions();
    return updateUrlForFilter(action$, store).let(flattenToPromise).then(() => {
      expect(true); // TODO: test that the location changes to '/store/category/wine?sort=price_asc',
    });
  });
});
