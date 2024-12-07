
import * as React from 'react';
import dm_factory from '@minibar/store-business/src/delivery_method/__tests__/delivery_method.factory';
import sc_factory from '@minibar/store-business/src/scheduling_calendar/__tests__/scheduling_calendar.factory';
import supplier_factory from '@minibar/store-business/src/supplier/__tests__/supplier.factory';
import cart_item_factory from 'store/business/cart_item/__tests__/cart_item.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import SchedulingPicker from '../SchedulingPicker';

describe('SchedulingPicker', () => {
  const delivery_methods = [dm_factory.build('on_demand', {id: 10}), dm_factory.build('shipped', {id: 15})];
  const shipment = {
    supplier: supplier_factory.build({delivery_methods}),
    delivery_method: delivery_methods[0],
    items: [cart_item_factory.build('five_dollar')]
  };

  it('renders', () => {
    const scheduling_calendar = sc_factory.build({id: 10}); // the first dm id
    const sc_norm = sc_factory.normalize(scheduling_calendar);
    const state = {
      scheduling_calendar: {
        by_id: sc_norm.entities.scheduling_calendar
      }
    };

    expect(render(
      <TestProvider initial_state={state} >
        <SchedulingPicker shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders a loader', () => {
    expect(render(
      <TestProvider>
        <SchedulingPicker shipment={shipment} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
