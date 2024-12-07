
import React from 'react';
import address_factory from 'store/business/address/__tests__/address.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import AddressPage from '../AddressPage';

describe('AddressPage', () => {
  it('renders', () => {
    const current_address = address_factory.build();

    expect(render(
      <TestProvider>
        <AddressPage current_address={current_address} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
