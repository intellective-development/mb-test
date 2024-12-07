// @flow
import _ from 'lodash';
import type { ProductGrouping } from '../product_grouping';
import type { Variant } from '../variant';
import type { ExternalProduct } from '../external_product';

export const getItemData = (product_grouping: ProductGrouping, variant: Variant, quantity: number = 1) => ({
  id: variant.id,
  name: product_grouping.name,
  category: product_grouping.hierarchy_category.name,
  price: variant.price,
  brand: product_grouping.brand_data.permalink,
  contents: [
    {
      id: variant.product_id,
      item_price: variant.price,
      item_location_code: variant.supplier_id,
      quantity: quantity
    }
  ],
  value: variant.price * quantity
});

export const getCartItemData = (product_grouping: ProductGrouping, variant: Variant, quantity: number) => ({
  ...getItemData(product_grouping, variant, quantity),
  quantity
});


export const getExternalItemData = (product_grouping: ProductGrouping, external_product: ExternalProduct) => ({
  id: external_product.id,
  name: product_grouping.name,
  brand: product_grouping.brand_data.permalink,
  category: product_grouping.hierarchy_category.name
});

// based on server-side order, but more important to be consistent than exact
export const FILTER_ORDER = [
  'hierarchy_category',
  'hierarchy_type',
  'hierarchy_subtype',
  'country',
  'region',
  'brand',
  'search_volume',
  'price'
];
const getSortValue = (sort_order: string[], value: string) => sort_order.indexOf(value);
export const sortKVPairsByKeys = (order) => ([a], [b]) => {
  const value_a = getSortValue(order, a);
  const value_b = getSortValue(order, b);

  if (value_a === -1 && value_b === -1){
    return a > b ? 1 : -1; // alphabetical sort
  } else if (value_a === -1){
    return 1; // prioritize b
  } else if (value_b === -1){
    return -1; // prioritize a
  } else {
    return value_a > value_b ? 1 : -1;
  }
};
export const stringifyFilter = (filter: { [key: string]: any }) => {
  const unique_order = [filter.base, ...FILTER_ORDER];
  const sorted_filters = Object.entries(filter)
    .filter(([key]) => key !== 'base')
    .sort(sortKVPairsByKeys(unique_order));
  const action = sorted_filters
    .map(([key]) => key)
    .join('/');
  const label = sorted_filters
    .map(([_key, value]) => (_.isArray(value) ? value.join(',') : value))
    .join('/');
  return { action, label }; // each has a 500 byte limit
};
