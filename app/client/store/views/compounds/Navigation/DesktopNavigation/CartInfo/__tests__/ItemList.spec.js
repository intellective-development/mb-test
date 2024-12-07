import React from 'react';
import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';
import product_grouping_factory from 'store/business/product_grouping/__tests__/product_grouping.factory';
import variant_factory from 'store/business/variant/__tests__/variant.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import ItemList from '../ItemList';

describe('ItemList', () => {
  // we use an explicit variant and pg factories to ensure they have unique ids
  const makeCartItem = () => (cart_item_factory.build({
    variant: variant_factory.build(),
    product_grouping: product_grouping_factory.build()
  }));

  it('renders', () => {
    const cart_items = [makeCartItem(), makeCartItem()];

    expect(render(
      <TestProvider>
        <ItemList items={cart_items} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders with overflow', () => {
    const cart_items = [
      makeCartItem(),
      makeCartItem(),
      makeCartItem(),
      makeCartItem(),
      makeCartItem(),
      makeCartItem()
    ];

    expect(render(
      <TestProvider>
        <ItemList items={cart_items} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
