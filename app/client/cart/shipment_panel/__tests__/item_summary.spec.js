import * as React from 'react';

import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';

import ItemSummary from '../item_summary';

describe('ItemSummary', () => {
  it('it renders item summary without special offer when ther is no two_for_one deal', () => {
    const item = cart_item_factory.build('ten_dollar', {quantity: 1});
    expect(render(
      <TestProvider>
        <ItemSummary item={item} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('it renders item summary with special offer when ther is a two_for_one deal', () => {
    const item = cart_item_factory.build('with_two_for_one_deal');
    expect(render(
      <TestProvider>
        <ItemSummary item={item} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
