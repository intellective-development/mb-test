/* eslint import/first: 0 */

jest.mock('legacy_store/models/Cart');

import * as React from 'react';

import supplier_factory from 'client/store/business/supplier/__tests__/supplier.factory';
import TestProvider from 'store/views/__tests__/utils/TestProvider';
import SupplierSwitching from '../SupplierSwitching';

describe('SupplierSwitching', () => {
  it('renders', () => {
    const alternative_suppliers = [
      supplier_factory.build('with_delivery_methods'),
      supplier_factory.build('with_delivery_methods')
    ];
    const current_supplier = supplier_factory.build('with_delivery_methods', {
      alternative_supplier_ids: alternative_suppliers.map(s => s.id)
    });

    const initial_state = {
      ...supplier_factory.stateify([...alternative_suppliers, current_supplier])
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <SupplierSwitching supplier_id={current_supplier.id} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
