
import React from 'react';
import address_factory from 'store/business/address/__tests__/address.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import DeliveryLink from '../DeliveryLink';

describe('DeliveryLink', () => {
  it('renders', () => {
    const initial_state = {
      ...address_factory.stateify(
        address_factory.build({local_id: '10'})
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <DeliveryLink />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders without address', () => {
    expect(render(
      <TestProvider initial_state={{}}>
        <DeliveryLink />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
