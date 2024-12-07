// @flow

import _ from 'lodash';
import uuid from 'uuid';
import { makeBuildFactory, sequence } from '@minibar/store-business/src/__tests__/utils/factory';
import type { BuildFactory, FunctionAttributable } from '@minibar/store-business/src/__tests__/utils/factory';

import product_grouping_factory from '../../product_grouping/__tests__/product_grouping.factory';
import supplier_factory from '../../supplier/__tests__/supplier.factory';
import type { SearchSwitch } from '../index';

const default_attrs: FunctionAttributable<SearchSwitch> = {
  product_grouping_ids: [sequence()],
  supplier_id: sequence()
};

const traits = {};

type BuildProductListFactory = BuildFactory<SearchSwitch, typeof traits>;
const buildFactory: BuildProductListFactory = makeBuildFactory(default_attrs, traits);
const stateifyFactory = (search_switch: SearchSwitch, search_switch_id: ?string = uuid()) => {
  const product_groupings = search_switch.product_grouping_ids.map(pg_id => (
    product_grouping_factory.build('with_variants', {permalink: pg_id})
  ));
  const supplier = supplier_factory.build('with_delivery_methods', {id: search_switch.supplier_id});

  const supplier_state = {
    ...supplier_factory.stateify([supplier]),
    supplier: {
      // we remove the current_ids from the supplier state, as this is an alternative
      ...supplier_factory.stateify([supplier]).supplier,
      current_ids: []
    }
  };

  const product_grouping_state = _.pick(product_grouping_factory.stateify(product_groupings), ['product_grouping', 'variant']);

  return {
    ...supplier_state,
    search_switch: {
      by_id: {[search_switch_id]: search_switch},
      ...product_grouping_state
    }
  };
};

export default {
  build: buildFactory,
  stateify: stateifyFactory
};
