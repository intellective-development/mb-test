
import React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import SearchInput from '../SearchInput';

describe('SearchInput', () => {
  it('renders', () => {
    expect(render(
      <TestProvider initial_state={{}}>
        <SearchInput />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
