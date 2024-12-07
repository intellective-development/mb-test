
import * as React from 'react';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import SupplierSummary from '../supplier_summary';

describe('SupplierSummary', () => {
  it('renders', () => {
    const delivery_method = dm_factory.build();
    const supplier = supplier_factory.build({delivery_methods: [delivery_method]});
    const shipment = { supplier };

    expect(render(
      <TestProvider>
        <SupplierSummary shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders for pickup shipment', () => {
    const delivery_method = dm_factory.build('pickup');
    const supplier = supplier_factory.build({delivery_methods: [delivery_method]});
    const shipment = { supplier };

    expect(render(
      <TestProvider>
        <SupplierSummary shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
