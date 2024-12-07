// @flow

import { makeBuildFactory, makeNormalizeFactory, sequence } from '@minibar/store-business/src/__tests__/utils/factory';
import { cart_share_schema } from '@minibar/store-business/src/networking/schemas';
import { address_factory } from 'store/business/address/__tests__/address.factory';
import cart_share_item_factory from './cart_share_item.factory';
// import type { CartShare } from '../index';

const default_attrs = {
  id: sequence(),
  share_type: 'cart_abandonment',
  coupon_code: 'MB10101',
  address: null,
  available_cart_share_items: [],
  preferred_supplier_ids: []
};

const traits = {
  with_address: {address: address_factory.build()},
  with_items: {address: [cart_share_item_factory.build(), cart_share_item_factory.build()]},
  with_preferred_supplier_ids: {address: [1, 2, 3]}
};

const buildFactory = makeBuildFactory(default_attrs, traits);
const normalizeFactory = makeNormalizeFactory(cart_share_schema);

export default {
  build: buildFactory,
  normalize: normalizeFactory
};
