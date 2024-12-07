import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import product_grouping_factory from 'store/business/product_grouping/__tests__/product_grouping.factory';
import { ProductDetailScene } from '../index';

jest.mock('shared/components/higher_order/make_provided'); // avoid importing the full store

//const internal_product_grouping = product_grouping_factory.build('with_variants');
const external_product_grouping = product_grouping_factory.build('external');
const empty_product_grouping = product_grouping_factory.build();

describe('ProductDetailScene', () => {
  const shared_props = {
    supplier_ids: [],
    variant_permalink: null,
    product_grouping_permalink: 'bad-beer',
    fetchInitialProduct: () => null,
    fetchProduct: () => null
  };

  it('renders loading spinner when there is no product', () => {
    expect(render(
      <TestProvider >
        <ProductDetailScene
          {...shared_props}
          has_checked_for_suppliers={false}
          has_current_suppliers={false}
          product_grouping={undefined} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders ProductDetailExternal when the product grouping is external', () => {
    expect(render(
      <TestProvider >
        <ProductDetailScene
          {...shared_props}
          has_checked_for_suppliers
          has_current_suppliers={false}
          product_grouping={external_product_grouping} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  /* TODO: fix the test
  it('renders ProductDetailInternal with an add to cart when the product grouping is internal', () => {
    expect(render(
      <TestProvider >
        <ProductDetailScene
          {...shared_props}
          has_checked_for_suppliers
          has_current_suppliers
          product_grouping={internal_product_grouping} />
      </TestProvider>
    )).toMatchSnapshot();
  }); */

  it('renders the frame with a loader when we have current suppliers but no internal product_grouping', () => {
    expect(render(
      <TestProvider>
        <ProductDetailScene
          {...shared_props}
          has_current_suppliers
          has_checked_for_suppliers
          product_grouping={external_product_grouping} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders unavailable panel when the product grouping is internal but has no variants', () => {
    expect(render(
      <TestProvider >
        <ProductDetailScene
          {...shared_props}
          has_checked_for_suppliers
          has_current_suppliers
          product_grouping={empty_product_grouping} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
