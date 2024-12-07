import * as React from 'react';
import address_factory from 'client/store/business/address/__tests__/address.factory';
import TestProvider from 'store/views/__tests__/utils/TestProvider';
import AddressSection from '../AddressSection';

describe('AddressSection', () => {
  it('renders', () => {
    const address_norm = address_factory.normalize(address_factory.build());
    const initial_state = {
      address: {
        by_id: address_norm.entities.address,
        current_delivery_address_id: address_norm.result
      }
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <AddressSection />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
