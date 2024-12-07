import * as React from 'react';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';
import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import { hasShopRunnerToken } from 'client/shared/utils/shop_runner';
import DeliverySummary from '../delivery_summary';

jest.mock('client/shared/utils/shop_runner');

describe('DeliverySummary', () => {
  it('renders', () => {
    const delivery_methods = [dm_factory.build('on_demand'), dm_factory.build('shipped')];
    const shipment = {
      supplier: supplier_factory.build({delivery_methods}),
      delivery_method: delivery_methods[0],
      items: [cart_item_factory.build('five_dollar')]
    };

    expect(render(
      <TestProvider>
        <DeliverySummary shipment={shipment} delivery_method={delivery_methods[0]} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders ShopRunner divs', () => {
    const delivery_methods = [dm_factory.build('on_demand'), dm_factory.build('shipped')];
    const shipment = {
      supplier: supplier_factory.build({delivery_methods}),
      delivery_method: delivery_methods[0],
      items: [cart_item_factory.build('five_dollar')]
    };

    hasShopRunnerToken.mockReturnValue(true);

    expect(render(
      <TestProvider>
        <DeliverySummary shipment={shipment} delivery_method={delivery_methods[0]} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
