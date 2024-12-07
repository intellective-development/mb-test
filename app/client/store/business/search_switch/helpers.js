// @flow

import _ from 'lodash';
import type { SearchSwitch } from './reducer';

export const getProductGroupingIds = (search_switch: SearchSwitch) => search_switch.product_grouping_ids;
export const getSupplierId = (search_switch: SearchSwitch) => search_switch.supplier_id;
export const isEmpty = (search_switch: SearchSwitch) => {
  return _.isEmpty(getProductGroupingIds(search_switch)) || !getSupplierId(search_switch);
};
