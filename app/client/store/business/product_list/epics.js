// @flow

import * as product_list_epics from '@minibar/store-business/src/product_list/epics';
import { filter_helpers } from '../filter';

const { makeFetchProducts, ...epics } = product_list_epics;

export default {
  ...epics,
  fetchProducts: makeFetchProducts(filter_helpers.facetWhitelist)
};
