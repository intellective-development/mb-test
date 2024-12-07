import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import AddressEntry from '../index';

describe('AddressEntry', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <AddressEntry recent_addresses={[]} submitAddress={() => {}} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders when show_placeholder is true', () => {
    expect(render(
      <TestProvider>
        <AddressEntry recent_addresses={[]} submitAddress={() => {}} show_placeholder />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
