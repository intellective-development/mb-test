import * as React from 'react';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import SupplierMap from '../SupplierMap';

describe('SupplierMap', () => {
  it('renders', () => {
    const supplier_id = 1;
    const supplier = supplier_factory.build('with_delivery_methods', {id: supplier_id});
    const state = supplier_factory.stateify([supplier]);

    expect(render(
      <TestProvider initial_state={state}>
        <SupplierMap supplier_id={supplier_id} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
