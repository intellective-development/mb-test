// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { filter_helpers } from 'store/business/filter';
import type { Filter } from 'store/business/filter';
import { product_list_actions, product_list_constants, product_list_helpers } from 'store/business/product_list';

import { MBTouchable } from '../../../elements';

type FilterTogglesProps = {
  filter: Filter,
  facets: product_list_constants.Facet[],
  product_list_id: string,

  // DTP
  setFilter: typeof product_list_actions.setFilter
};
const FilterToggles = ({filter, facets, product_list_id, setFilter}: FilterTogglesProps) => {
  const makeSelectFilterElement = (facet_name: string, facet_option_term: mixed) => () => {
    const next_filter = filter_helpers.toggleFilterProperty(filter, facet_name, facet_option_term);
    setFilter(product_list_id, next_filter);
  };

  const elements = _.flatten(facets
    .filter(validBreadcrumbFacet)
    .map((facet) => (
      selectedFacetOptions(facet, filter).map(facet_option => (
        <FilterElement
          facet_option={facet_option}
          facet={facet}
          product_list_id={product_list_id}
          selectFilterElement={makeSelectFilterElement(facet.name, facet_option.term)}
          key={`${facet.name}__${facet_option.term}`} />
      ))
    )));

  return (
    <ul className="inline-list">
      {elements}
    </ul>
  );
};

const FilterElement = ({facet_option, selectFilterElement}) => {
  return (
    <li>
      <MBTouchable className="filter-toggle" onClick={selectFilterElement}>
        {facet_option.description}
      </MBTouchable>
    </li>
  );
};

const validBreadcrumbFacet = (facet) => {
  return !['hierarchy_type', 'hierarchy_subtype'].includes(facet.name);
};


const selectedFacetOptions = (facet, filter) => {
  const filter_facet_values = _.toArray(filter[facet.name]); // wrap single values in an array if necessary

  return _.compact(filter_facet_values.map(filter_facet_value => product_list_helpers.getFacetTermByValue(facet, filter_facet_value)));
};

const FilterTogglesDTP = { setFilter: product_list_actions.setFilter };
const FilterTogglesContainer = connect(null, FilterTogglesDTP)(FilterToggles);

export default FilterTogglesContainer;
