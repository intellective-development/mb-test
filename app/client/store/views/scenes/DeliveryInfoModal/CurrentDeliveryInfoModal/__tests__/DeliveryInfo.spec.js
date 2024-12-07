import React from 'react';

import address_factory from 'client/store/business/address/__tests__/address.factory';
import supplier_factory from 'client/store/business/supplier/__tests__/supplier.factory';
import TestProvider from 'store/views/__tests__/utils/TestProvider';
import DeliveryInfo from '../DeliveryInfo';

describe('DeliveryInfo', () => {
  it('renders', () => {
    const address_norm = address_factory.normalize(address_factory.build());
    const supplier_norm = supplier_factory.normalize([supplier_factory.build()]);

    const initial_state = {
      address: {
        by_id: {
          ...supplier_norm.entities.address,
          ...address_norm.entities.address
        },
        current_delivery_address_id: address_norm.result
      },
      supplier: {
        by_id: supplier_norm.entities.supplier,
        current_ids: supplier_norm.result
      }
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <DeliveryInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
