import * as React from 'react';
import TestProvider from 'store/views/__tests__/utils/TestProvider';

import ShipmentList from '../index';

jest.mock('legacy_store/collections/Suppliers');
jest.mock('legacy_store/models/Cart');
jest.mock('legacy_store/models/Order');
jest.mock('client/shared/components/higher_order/make_provided'); // avoid importing the full store

describe('ShipmentList', () => {
  // TODO: test with actual shipment state

  it('renders', () => {
    expect(render(
      <TestProvider>
        <ShipmentList />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
