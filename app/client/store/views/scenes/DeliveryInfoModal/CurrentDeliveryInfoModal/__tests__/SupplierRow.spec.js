import * as React from 'react';
import supplier_factory from 'client/store/business/supplier/__tests__/supplier.factory';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import SupplierRow from '../SupplierRow';

describe('SupplierRow', () => {
  it('renders', () => {
    const supplier = supplier_factory.build('with_delivery_methods');

    expect(render(
      <TestProvider>
        <SupplierRow supplier={supplier} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders a supplier that has a pickup delivery method', () => {
    const delivery_methods = [dm_factory.build('pickup'), dm_factory.build('shipped')];
    const supplier = supplier_factory.build({delivery_methods});

    expect(render(
      <TestProvider>
        <SupplierRow supplier={supplier} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
