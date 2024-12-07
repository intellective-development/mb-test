
import Rx from 'rxjs';
import { createStore } from 'redux';
import * as api from '@minibar/store-business/src/networking/api';
import baseReducer from 'store/business/base_reducer';
import filter_factory from 'store/business/filter/__tests__/filter.factory';
import product_list_factory from 'store/business/product_list/__tests__/product_list.factory';

import * as search_switch_actions from '../actions';
import pg_factory from '../../product_grouping/__tests__/product_grouping.factory';
import supplier_factory from '../../supplier/__tests__/supplier.factory';

import {
  fetchSearchSwitchProductGroupings
} from '../epics';


jest.mock('@minibar/store-business/src/networking/api');


// TODO: make helpers
const createMBStore = (initial_state) => createStore(baseReducer, initial_state);
const flattenToPromise = (stream, action_count = 2) => stream.take(action_count).toArray().toPromise();

describe('fetchSearchSwitchProductGroupings', () => {
  const product_list_id = 'product-list-id';
  const product_list = product_list_factory.build('with_facets', {product_ids: []});
  const filter = filter_factory.build();
  const current_supplier = supplier_factory.build('with_delivery_methods', {id: 10, alternative_ids: [20, 30]});

  it('handles SEARCH_SWITCH:FETCH', () => {
    const trigger_action = search_switch_actions.fetchSearchSwitch(product_list_id);
    const action$ = Rx.Observable.of(trigger_action);
    const initial_state = {
      ...product_list_factory.stateify(product_list, product_list_id),
      ...filter_factory.stateify(filter, product_list_id),
      ...supplier_factory.stateify([current_supplier])
    };

    const stubbed_response = pg_factory.normalize(pg_factory.build());
    api.fetchProducts.mockReturnValue(Promise.resolve(stubbed_response));

    const store = createMBStore(initial_state);

    expect.hasAssertions();
    return fetchSearchSwitchProductGroupings(action$, store).let(flattenToPromise).then(([_loading_action, response_action]) => {
      expect(response_action).toEqual({
        type: 'SEARCH_SWITCH:FETCH__SUCCESS',
        payload: stubbed_response,
        meta: {
          product_list_id,
          request_data: expect.any(Object)
        }
      });

      expect(api.fetchProducts).toHaveBeenCalled();
    });
  });
});
