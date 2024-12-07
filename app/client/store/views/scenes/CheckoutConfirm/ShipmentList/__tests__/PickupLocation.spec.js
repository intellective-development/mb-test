import * as React from 'react';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';
import TestProvider from 'store/views/__tests__/utils/TestProvider';

import PickupLocation from '../PickupLocation';

describe('PickupLocation', () => {
  it('renders', () => {
    const delivery_method = dm_factory.build('pickup');
    const supplier = supplier_factory.build({delivery_methods: [delivery_method]});
    const shipment = {
      supplier,
      delivery_method
    };

    expect(render(
      <TestProvider>
        <PickupLocation shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders nothing if its a non pickup delivery method', () => {
    const delivery_method = dm_factory.build('on_demand');
    const supplier = supplier_factory.build({delivery_methods: [delivery_method]});
    const shipment = {
      supplier,
      delivery_method
    };

    expect(render(
      <TestProvider>
        <PickupLocation shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
