
import React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import BrowseBar from '../BrowseBar';

describe('BrowseBar', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <BrowseBar />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
