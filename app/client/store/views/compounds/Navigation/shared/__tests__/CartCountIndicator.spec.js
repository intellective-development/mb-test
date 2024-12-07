
import React from 'react';
import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import CartCountIndicator from '../CartCountIndicator';

describe('CartCountIndicator', () => {
  it('renders', () => {
    const initial_state = cart_item_factory.stateify([
      cart_item_factory.build('with_product_grouping', 'ten_dollar', {quantity: 1}),
      cart_item_factory.build('with_product_grouping', 'five_dollar', {quantity: 2})
    ]);

    expect(render(
      <TestProvider initial_state={initial_state}>
        <CartCountIndicator />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders when the cart is empty', () => {
    const initial_state = cart_item_factory.stateify([]);

    expect(render(
      <TestProvider initial_state={initial_state}>
        <CartCountIndicator />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
