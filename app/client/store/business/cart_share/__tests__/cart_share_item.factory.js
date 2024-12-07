// @flow

import { makeBuildFactory, makeNormalizeFactory } from '@minibar/store-business/src/__tests__/utils/factory';
import { cart_share_schema } from '@minibar/store-business/src/networking/schemas';
import type { CartShareItem } from '../index';

const default_attrs: CartShareItem = {
  quantity: 1,
  product: {}, // TODO: real factory
  product_grouping: {} // TODO: real factory
};

const traits = {};

const buildFactory = makeBuildFactory(default_attrs, traits);
const normalizeFactory = makeNormalizeFactory(cart_share_schema);

export default {
  build: buildFactory,
  normalize: normalizeFactory
};
