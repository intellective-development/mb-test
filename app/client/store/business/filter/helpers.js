// @flow

import { filter_helpers } from '@minibar/store-business/src/filter';
import type { Filter } from './index';

/*const CATEGORY_SPECIFIC_FACETS = {
  wine: ['country', 'price'],
  liquor: ['price', 'search_volume'],
  beer: ['search_volume']
};*/

export const facetWhitelist = (filter: Filter) => {
  if (filter && filter.hierarchy_category === 'mixers'){
    return ['selected_supplier', 'hierarchy_category', 'hierarchy_type', 'hierarchy_subtype', 'container_type', 'delivery_type', 'price'];
  }
  return ['selected_supplier', 'hierarchy_category', 'hierarchy_type', 'hierarchy_subtype', 'country', 'volume', 'container_type', 'delivery_type', 'price'];
};

export default {
  ...filter_helpers,
  facetWhitelist
};
