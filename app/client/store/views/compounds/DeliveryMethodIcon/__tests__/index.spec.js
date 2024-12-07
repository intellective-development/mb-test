
import React from 'react';

import DeliveryMethodIcon, { MultiDeliveryMethodIcon } from '../index';

describe('DeliveryMethodIcon', () => {
  const types = [
    ['on_demand'],
    ['pickup'],
    ['shipped']
  ];

  types.forEach(delivery_method_type => {
    it(`renders an icon for ${delivery_method_type}`, () => {
      expect(render(
        <DeliveryMethodIcon delivery_method_type={delivery_method_type} />
      )).toMatchSnapshot();
    });
  });
});

describe('MultiDeliveryMethodIcon', () => {
  const type_permutations = [
    ['on_demand'],
    ['pickup'],
    ['shipped'],
    ['on_demand', 'pickup'],
    ['on_demand', 'shipped'],
    ['pickup', 'shipped'],
    ['shipped', 'pickup'],
    ['shipped', 'pickup'],
    ['on_demand', 'on_demand'],
    ['on_demand', 'shipped', 'on_demand']
  ];

  type_permutations.forEach(delivery_method_types => {
    it(`renders an icon for ${delivery_method_types.join(', ')}`, () => {
      expect(render(
        <MultiDeliveryMethodIcon delivery_method_types={delivery_method_types} />
      )).toMatchSnapshot();
    });
  });
});
