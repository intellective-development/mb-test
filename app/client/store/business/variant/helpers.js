// @flow

import _ from 'lodash';
import { variant_helpers as shared_helpers } from '@minibar/store-business/src/variant';
import type { Variant } from './index';

export const formatVolumeShort = (variant: Variant) => {
  return _.compact([variant.short_pack_size, variant.short_volume]).join(' ');
};

export const getDefaultMinVariant = (product_grouping: ProductGrouping) => {
  const defaultVariant = shared_helpers.defaultVariant(product_grouping.variants);

  return _.minBy(_.filter(product_grouping.variants, variant => {
    return (defaultVariant.container ? variant.container === defaultVariant.container : true)
      && (defaultVariant.volume ? variant.volume === defaultVariant.volume : true);
  }), 'price');
};

export default {
  ...shared_helpers,
  formatVolumeShort,
  getDefaultMinVariant
};
