import * as React from 'react';
import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import { hasShopRunnerToken } from 'client/shared/utils/shop_runner';
import DeliveryCostPrompt from '../delivery_cost_prompt';

jest.mock('client/shared/utils/shop_runner');

describe('DeliveryCostPrompt', () => {
  const delivery_methods = [
    dm_factory.build('on_demand', {delivery_minimum: 25, free_delivery_threshold: 50}),
    dm_factory.build('shipped')
  ];
  const supplier = supplier_factory.build({delivery_methods});

  it('renders a below min warning when below the delivery_minimum', () => {
    const shipment = {
      supplier,
      delivery_method: delivery_methods[0],
      items: [cart_item_factory.build('ten_dollar', {quantity: 1})]
    };

    expect(render(
      <TestProvider>
        <DeliveryCostPrompt shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders a free threshold prompt when above the delivery_minimum but below the threshold', () => {
    const shipment = {
      supplier,
      delivery_method: delivery_methods[0],
      items: [cart_item_factory.build('ten_dollar', {quantity: 3})]
    };

    expect(render(
      <TestProvider>
        <DeliveryCostPrompt shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders nothing when a ShopRunner token is present', () => {
    hasShopRunnerToken.mockReturnValue(true);

    const shipment = {
      supplier,
      delivery_method: delivery_methods[0],
      items: [cart_item_factory.build('ten_dollar', {quantity: 3})]
    };

    expect(render(
      <TestProvider>
        <DeliveryCostPrompt shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders nothing when above both the delivery_minimum and the free_delivery_threshold', () => {
    const shipment = {
      supplier,
      delivery_method: delivery_methods[0],
      items: [cart_item_factory.build('ten_dollar', {quantity: 6})]
    };

    expect(render(
      <TestProvider>
        <DeliveryCostPrompt shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
