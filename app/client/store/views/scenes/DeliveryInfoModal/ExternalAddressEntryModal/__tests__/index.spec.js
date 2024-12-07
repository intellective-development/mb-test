import React from 'react';
import address_factory from 'store/business/address/__tests__/address.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import ExternalAddressEntryModal from '../index';

describe('ExternalAddressEntryModal', () => {
  it('renders', () => {
    const initial_state = address_factory.stateify(address_factory.build());

    expect(render(
      <TestProvider initial_state={initial_state}>
        <ExternalAddressEntryModal is_hidden={false} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
