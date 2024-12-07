/* eslint import/first: 0 */
jest.mock('client/shared/utils/shop_runner');

import * as React from 'react';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';

import DeliveryInfo from '../DeliveryInfo';
import { hasShopRunnerToken } from 'client/shared/utils/shop_runner';


describe('DeliveryInfo', () => {
  it('renders', () => {
    const shipment = {
      delivery_method: dm_factory.build('on_demand')
    };

    expect(render(
      <DeliveryInfo shipment={shipment} />
    )).toMatchSnapshot();
  });
  it('renders ShopRunner content', () => {
    const shipment = {
      delivery_method: dm_factory.build('on_demand')
    };

    hasShopRunnerToken.mockReturnValue(true);

    expect(render(
      <DeliveryInfo shipment={shipment} />
    )).toMatchSnapshot();
  });
});
