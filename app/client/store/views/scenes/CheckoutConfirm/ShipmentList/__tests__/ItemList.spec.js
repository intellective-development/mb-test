
import * as React from 'react';

// import TestProvider from 'store/views/__tests__/utils/TestProvider';
import ItemList from '../ItemList';

describe('ItemList', () => {
  // TODO: test with actual items

  it('renders', () => {
    const items = [];

    expect(render(
      <ItemList items={items} />
    )).toMatchSnapshot();
  });
});
