import React from 'react';
import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import ItemCell from '../ItemCell';

describe('ItemCell', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <ItemCell item={cart_item_factory.build('with_product_grouping', 'five_dollar')} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders with quantity > 1', () => {
    expect(render(
      <TestProvider>
        <ItemCell item={cart_item_factory.build('with_product_grouping', 'five_dollar', {quantity: 10})} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
