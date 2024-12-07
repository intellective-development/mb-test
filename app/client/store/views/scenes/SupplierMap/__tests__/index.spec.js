/* eslint import/first: 0 */
jest.mock('client/shared/components/higher_order/make_provided'); // avoid importing the full store

import * as React from 'react';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import { SupplierMapModal } from '../index';

describe('SupplierMapModal', () => {
  const supplier_id = 1;
  const supplier = supplier_factory.build('with_delivery_methods', {id: supplier_id});

  it('renders', () => {
    const state = {
      ...supplier_factory.stateify([supplier]),
      ui: {
        map_supplier_id: supplier_id
      }
    };
    expect(render(
      <TestProvider initial_state={state}>
        <SupplierMapModal supplier_id={supplier_id} show />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
