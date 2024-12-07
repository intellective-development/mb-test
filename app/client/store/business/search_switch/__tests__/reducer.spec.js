
import { makeSuccessAction } from '@minibar/store-business/src/utils/create_actions_for_request';
import pg_factory from 'store/business/product_grouping/__tests__/product_grouping.factory';
import variant_factory from 'store/business/variant/__tests__/variant.factory';

import { product_list_actions } from '../../product_list';
import * as search_switch_actions from '../actions';
import searchSwitchReducer, {
  searchSwitchByIdReducer,
  searchSwitchProductGroupingIdsReducer,
  searchSwitchSupplierIdReducer,
  productGroupingByIdReducer,
  variantByIdReducer
} from '../reducer';

const searchListFetchSuccess = makeSuccessAction('SEARCH_SWITCH:FETCH');

describe('searchSwitchReducer', () => {
  it('structures the state slice', () => {
    expect(Object.keys(searchSwitchReducer(undefined, {}))).toEqual([
      'by_id',
      'product_grouping',
      'variant'
    ]);
  });
});

describe('searchSwitchByIdReducer', () => {
  const product_list_id = 'my_list';
  const supplier_id = 1;
  const variants = [variant_factory.build({supplier_id}), variant_factory.build({supplier_id})];
  const product_groupings = [pg_factory.build({variants})];
  const n_product_groupings = pg_factory.normalize(product_groupings);
  const success_action = searchListFetchSuccess({
    entities: n_product_groupings.entities,
    result: { product_groupings: n_product_groupings.result }
  }, {product_list_id});
  const empty_success_action = searchListFetchSuccess({
    entities: {},
    result: { product_groupings: [] }
  }, {product_list_id});

  it('returns the initial state', () => {
    expect(searchSwitchByIdReducer(undefined, {})).toEqual({});
  });

  it('creates the entity when handling SEARCH_SWITCH:FETCH', () => {
    const trigger_action = search_switch_actions.fetchSearchSwitch(product_list_id);
    expect(searchSwitchByIdReducer(undefined, trigger_action)).toEqual({
      [product_list_id]: {
        product_grouping_ids: [],
        supplier_id: null
      }
    });
  });

  it('updates the entity when handling SEARCH_SWITCH:FETCH__SUCCESS', () => {
    expect(searchSwitchByIdReducer(undefined, success_action)).toEqual({
      [product_list_id]: {
        product_grouping_ids: product_groupings.map(pg => pg.permalink),
        supplier_id
      }
    });
  });

  it('removes the entity when handling PRODUCT_LIST:REMOVE_FILTER', () => {
    const action = product_list_actions.removeFilter('SEARCH_SWITCH_1');
    const current_state = {SEARCH_SWITCH_1: {}, SEARCH_SWITCH_2: {}};

    expect(searchSwitchByIdReducer(current_state, action)).toEqual({SEARCH_SWITCH_2: {}});
  });

  describe('searchSwitchProductGroupingIdsReducer', () => {
    it('returns the initial state', () => {
      expect(searchSwitchProductGroupingIdsReducer(undefined, {})).toEqual([]);
    });

    it('handles SEARCH_SWITCH:FETCH__SUCCESS', () => {
      expect(searchSwitchProductGroupingIdsReducer([], success_action))
        .toEqual(product_groupings.map(pg => pg.permalink));
    });

    it('handles SEARCH_SWITCH:FETCH__SUCCESS when there are no results', () => {
      expect(searchSwitchProductGroupingIdsReducer([], empty_success_action)).toEqual([]);
    });
  });

  describe('searchSwitchSupplierIdReducer', () => {
    it('returns the initial state', () => {
      expect(searchSwitchSupplierIdReducer(undefined, {})).toEqual(null);
    });

    it('handles SEARCH_SWITCH:FETCH__SUCCESS', () => {
      expect(searchSwitchSupplierIdReducer([], success_action)).toEqual(supplier_id);
    });

    it('handles SEARCH_SWITCH:FETCH__SUCCESS when there are no results', () => {
      expect(searchSwitchSupplierIdReducer([], empty_success_action)).toEqual(null);
    });
  });
});


describe('productGroupingByIdReducer', () => {
  it('returns the initial state', () => {
    expect(productGroupingByIdReducer(undefined, {})).toEqual({});
  });

  it('handles PRODUCT_LIST:FETCH_PRODUCTS__SUCCESS', () => {
    const permalink = 'my-product';
    const product_grouping = pg_factory.build({permalink: permalink, id: permalink, original_id: permalink});
    const { entities } = pg_factory.normalize(product_grouping);
    const action = searchListFetchSuccess({entities});

    expect(productGroupingByIdReducer(undefined, action)).toEqual({[permalink]: product_grouping});
  });
});

describe('variantByIdReducer', () => {
  const variant_id = 1000;
  const variant = variant_factory.build({id: variant_id});
  const product_grouping = pg_factory.build({variants: [variant]});

  it('returns the initial state', () => {
    expect(variantByIdReducer(undefined, {})).toEqual({});
  });

  it('handles PRODUCT_LIST:FETCH_PRODUCTS__SUCCESS', () => {
    const { entities } = pg_factory.normalize(product_grouping);
    const action = searchListFetchSuccess({entities});

    expect(variantByIdReducer(undefined, action)).toEqual({[variant_id]: variant});
  });
});
