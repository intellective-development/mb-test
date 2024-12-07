import * as React from 'react';
import { render } from 'enzyme';

import VariantItem from '../VariantItem';

const default_variant = {
  supplier: {
    best_delivery_fee: 5,
    best_delivery_minimum: 25,
    deliveryMethods: [{
      delivery_fee: 5,
      delivery_minimum: 25,
      hours: {
        always_open: true
      }
    }]
  },
  productGrouping: {
    tags: []
  },
  original_price: 14.99,
  price: 14.99
};

const null_threshold_variant = {
  ...default_variant
};

const free_variant = {
  ...default_variant,
  supplier: {
    ...default_variant.supplier,
    best_delivery_fee: 0,
    deliveryMethods: [{
      ...default_variant.supplier.deliveryMethods[0],
      delivery_fee: 0
    }]
  }
};

const price_over_threshold_variant = {
  ...default_variant,
  supplier: {
    ...default_variant.supplier,
    deliveryMethods: [{
      ...default_variant.supplier.deliveryMethods[0],
      free_delivery_threshold: 10
    }]
  }
};

const price_under_threshold_variant = {
  ...price_over_threshold_variant,
  original_price: 4.99,
  price: 4.99
};

describe('VariantItem', () => {
  it('Renders shipping cost when no threshold', () => {
    expect(render(
      <VariantItem variant={null_threshold_variant} />
    ).text()).toContain('+$5.00 delivery');
  });

  it('Renders free when no fee', () => {
    expect(render(
      <VariantItem variant={free_variant} />
    ).text()).toContain('Free delivery');
  });

  it('Renders free when price exceeds threshold', () => {
    expect(render(
      <VariantItem variant={price_over_threshold_variant} />
    ).text()).toContain('Free delivery');
  });

  it('Renders delivery fee when price does not exceed threshold', () => {
    expect(render(
      <VariantItem variant={price_under_threshold_variant} />
    ).text()).toContain('+$5.00 delivery');
  });
});
