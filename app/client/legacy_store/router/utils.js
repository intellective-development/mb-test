// @flow

import _ from 'lodash';
import qs from '../../utils/qs';
import { encodeObject, decodeObject } from 'shared/utils/convert_utf8_b64';
import { filter_constants, filter_helpers } from 'store/business/filter';
import type { Filter } from 'store/business/filter';
import { product_list_constants } from 'store/business/product_list';

export function encodePLPParams(filter: $Shape<Filter>, sort?: product_list_constants.SortOptionId, base_url_filter: Object = {}){
  const param_filter = _.omit(filter, Object.keys(base_url_filter));

  // We protect the types of the more complex filter attrs options by encoding them with JSON
  // TODO: We shouldn't strictly need this, though there are non-string types in the filter.
  // We should consider a separate function to handle those on a case by case basis.
  const formatted_filter = _.mapValues(param_filter, (filter_value: Object, filter_attr: string) => {
    return JSON.stringify(filter_value);
  });

  // note that sort will not be included out if it is undefined, as qs ignoes undefined keys
  return qs.stringify({...formatted_filter, sort});
}

export function decodePLPParams(params: ?string){
  if (!params) return {};

  const { sort, ...rest_params } = qs.parse(params);
  const filter = _.pick(rest_params, filter_constants.FILTER_KEYS);

  // as we encode the Filter's selected attrs in the URL, we need to decode them here
  const parsed_filter = _.mapValues(filter, (filter_value: string, filter_attr: string) => {
    return JSON.parse(filter_value);
  });

  return { sort, filter: parsed_filter };
}

export const isExternallyNavigable = (destination: string) => { // TODO: test
  const is_brand_plp = /store\/brand\//.test(destination);
  const is_pdp = /store\/product\//.test(destination);

  return is_brand_plp || is_pdp;
};

export const navigateTo = function(destination: string, options: Object = {trigger: true}){
  const short_destination = window.Minibar.stripUrlBase(destination);
  window.Minibar.navigateOrReload(short_destination, options);
};