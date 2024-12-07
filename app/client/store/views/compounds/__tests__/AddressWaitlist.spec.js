import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import AddressWaitlist from '../AddressWaitlist';

describe('AddressWaitlist', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <AddressWaitlist />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
