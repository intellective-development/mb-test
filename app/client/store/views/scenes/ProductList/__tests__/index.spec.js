import * as React from 'react';
import _ from 'lodash';
import { request_status_constants } from 'store/business/request_status';
import filter_factory from 'store/business/filter/__tests__/filter.factory';
import product_list_factory from 'store/business/product_list/__tests__/product_list.factory';
import product_grouping_factory from 'store/business/product_grouping/__tests__/product_grouping.factory';
import search_switch_factory from 'store/business/search_switch/__tests__/search_switch.factory';
import supplier_factory from 'store/business/supplier/__tests__/supplier.factory';
import request_status_factory from 'store/business/request_status/__tests__/request_status.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import { __private__ } from '../index';

const { ProductListSceneContainer: ProductListScene } = __private__;

jest.mock('legacy_store/models/Cart');

const stubbed_product_list_id = 'abc123';

describe('ProductListScene', () => {
  it('renders a full page loader when it does not have a product_list', () => {
    const initial_state = {
      product_list: { by_id: {} },
      session: { has_checked_for_suppliers: true }
    };

    expect(
      render(
        <TestProvider initial_state={initial_state}>
          <ProductListScene product_list_id={stubbed_product_list_id} />
        </TestProvider>
      )
    ).toMatchSnapshot();
  });

  it('renders a full page loader when it has not checked for suppliers', () => {
    const initial_state = {
      product_list: { by_id: { a: {} } },
      session: { has_checked_for_suppliers: false }
    };

    expect(
      render(
        <TestProvider initial_state={initial_state}>
          <ProductListScene product_list_id={stubbed_product_list_id} />
        </TestProvider>
      )
    ).toMatchSnapshot();
  });

  const session_state = { session: { has_checked_for_suppliers: true } };

  describe('internal', () => {
    it('renders a loader with a header when the list is first being fetched', () => {
      const product_list = product_list_factory.build('with_facets', {product_ids: [], is_fetching: true});
      const filter = filter_factory.build('hierarchy_category');

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });

    it('renders a list of content when it has a product_list with products', () => {
      const product_groupings = [
        product_grouping_factory.build('with_variants', {name: 'Bud', permalink: 'bud', id: 'bud'}),
        product_grouping_factory.build('with_variants', {name: 'DogfishHead', permalink: 'dogfish-head', id: 'bud'})
      ];
      const product_list = product_list_factory.build('with_facets', {product_ids: product_groupings.map(pg => pg.id)});
      const filter = filter_factory.build('hierarchy_category');

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id),
        ...product_grouping_factory.stateify(product_groupings)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });

    it('renders the search switcher loader if the product_list is empty and the search_switch is loading', () => {
      const product_list = product_list_factory.build('with_facets', {product_ids: []});
      const filter = filter_factory.build('hierarchy_category');

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id),
        ...request_status_factory.stateify('SEARCH_SWITCH:FETCH', stubbed_product_list_id, request_status_constants.LOADING_STATUS)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });

    it('renders the search switcher if it has items and the product_list is empty', () => {
      const product_list = product_list_factory.build('with_facets', {product_ids: []});
      const filter = filter_factory.build('hierarchy_category');
      const search_switch = search_switch_factory.build({product_grouping_ids: ['1', '2']});
      const current_supplier = supplier_factory.build('with_delivery_methods');

      // this requires a deep merge because we need both the alternative suppliers introduced by search_switch_factory
      // and the current suppliers from supplier_factory
      const search_switch_state = _.merge(
        search_switch_factory.stateify(search_switch, stubbed_product_list_id),
        supplier_factory.stateify([current_supplier])
      );

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id),
        ...search_switch_state
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });

    it('renders an empty state if the search switcher and product list have loaded and have no products', () => {
      const product_list = product_list_factory.build('with_facets', {product_ids: []});
      const filter = filter_factory.build('hierarchy_category');
      const search_switch = search_switch_factory.build({product_grouping_ids: []});

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id),
        ...search_switch_factory.stateify(search_switch, stubbed_product_list_id)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });
  });

  describe('external', () => {
    it('renders a loader with a header when the list is first being fetched', () => {
      const product_list = product_list_factory.build('external', {product_ids: [], is_fetching: true});
      const filter = filter_factory.build('hierarchy_category');

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });

    it('renders a list of content when it has a product_list with products', () => {
      const product_groupings = [
        product_grouping_factory.build('external', {name: 'Bud', permalink: 'bud', id: 'bud'}),
        product_grouping_factory.build('external', {name: 'DogfishHead', permalink: 'dogfish-head', id: 'bud'})
      ];

      const product_list = product_list_factory.build('external', {product_ids: product_groupings.map(pg => pg.id)});
      const filter = filter_factory.build('hierarchy_category');

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id),
        ...product_grouping_factory.stateify(product_groupings)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });

    it('renders an empty state if the product list has loaded and has no products', () => {
      const product_list = product_list_factory.build('external', {product_ids: []});
      const filter = filter_factory.build('hierarchy_category');

      const initial_state = {
        ...session_state,
        ...product_list_factory.stateify(product_list, stubbed_product_list_id),
        ...filter_factory.stateify(filter, stubbed_product_list_id)
      };

      expect(
        render(
          <TestProvider initial_state={initial_state}>
            <ProductListScene product_list_id={stubbed_product_list_id} />
          </TestProvider>
        )
      ).toMatchSnapshot();
    });
  });
});
