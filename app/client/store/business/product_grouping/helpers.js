// @flow

import { product_grouping_helpers as shared_helpers } from '@minibar/store-business/src/product_grouping';
import I18n from 'store/localization';
import type { ExternalProduct } from '../external_product';
import type { Variant } from '../variant';
import type { ProductGrouping } from './index';

const TAG_WHITELIST = ['flash_deal', 'category_feature', 'staff_pick', 'sale'];
export const primaryTag = (product_grouping: ProductGrouping) => {
  // first, loop over the tags, returning those that are whitelisted
  const eligible_tags = product_grouping.tags.filter(tag => TAG_WHITELIST.includes(tag));

  // sort by their index in the tag whitelist, since that's in priority order
  const sorted_tags = eligible_tags.sort(tag => TAG_WHITELIST.indexOf(tag));

  // maps name to display name
  return I18n.t(`client_entities.product_grouping.tags.${sorted_tags[0]}`, {defaultValue: ''});
};

const PERMALINK_BASE = '/store/product';
export const fullPermalink = (product_grouping: ProductGrouping, product?: Variant | ExternalProduct) => {
  if (product){
    return `${PERMALINK_BASE}/${product_grouping.permalink}/${product.permalink}`;
  } else {
    return `${PERMALINK_BASE}/${product_grouping.permalink}`;
  }
};

// TODO Remove this once all analytics are in redux
export const trackingData = (product_grouping: ProductGrouping, variant: Variant) => ({ // TODO: test
  id: variant.id,
  name: product_grouping.name,
  category: product_grouping.hierarchy_category.name,
  price: variant.price
});

export default {
  ...shared_helpers,
  primaryTag,
  fullPermalink,
  trackingData
};
