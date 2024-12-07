import * as React from 'react';
import { render } from 'enzyme';

import supplier_factory from 'store/business/supplier/__tests__/supplier.factory';
import variant_factory from 'store/business/variant/__tests__/variant.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';

import SupplierList from '../StoresDeliveryList';

const supplier_id = 1;
const variants = [variant_factory.build({supplier_id}), variant_factory.build({supplier_id})];

const suppliers = [
  supplier_factory.build('with_delivery_methods', {id: supplier_id})
];

const default_props = {
  id: 'goose-island-ipa',
  name: 'Goose Island IPA',
  product_name: 'Goose Island IPA',
  description: null,
  tags: [
    'hp_placement',
    '6pack',
    'craft-beer',
    'beer-promo',
    'gooseisland',
    'top_beer',
    'category_feature'
  ],
  type: 'domestic',
  category: 'beer',
  brand: 'R. Rostaing',
  hierarchy_category: {
    permalink: 'beer',
    name: 'beer'
  },
  hierarchy_type: {
    permalink: 'beer-domestic',
    name: 'domestic'
  },
  hierarchy_subtype: {
    permalink: null,
    name: null
  },
  brand_data: {
    permalink: 'r-rostaing',
    name: 'R. Rostaing'
  },
  thumb_url: '/product_defaults/small.jpg',
  image_url: '/product_defaults/product.jpg',
  properties: [
    {
      name: 'Alcohol %',
      value: 5.9
    },
    {
      name: 'Region',
      value: 'Chicago'
    }
  ],
  permalink: 'goose-island-ipa',
  product_content: false,
  variants: variants,
  external_products: [],
  supplier_id: supplier_id,
  deals: [],
  browse_type: 'INTERNAL',
  original_id: 773,
  default_variant_permalink: null
};

const initial_state = {
  ...supplier_factory.stateify(suppliers)
};

const no_variants = {
  ...default_props,
  variants: []
};

describe('SupplierList', () => {
  it('Renders variants', () => {
    expect(render(
      <TestProvider initial_state={initial_state}>
        <SupplierList {...default_props} />
      </TestProvider>
    ).text()).toContain('Size: 6 pack, 12oz bottles');
  });

  it('Renders with no variant', () => {
    expect(render(
      <TestProvider initial_state={initial_state}>
        <SupplierList {...no_variants} />
      </TestProvider>
    ).text()).toContain('This product is not available at your address');
  });
});

