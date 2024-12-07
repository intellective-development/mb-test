
import React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import MobileNavigation from '../index';

describe('MobileNavigation', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <MobileNavigation />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
