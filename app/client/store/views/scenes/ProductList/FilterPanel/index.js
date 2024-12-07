import React from 'react';
import { connect } from 'react-redux';
import { filter_helpers } from '../../../../business/filter';
import { product_list_actions } from '../../../../business/product_list';
import { FilterPanel } from './FilterPanel';

export const setFilterOption = ({
  filter,
  name,
  productListId,
  setFilter,
  term
}) => {
  const nextFilter = filter_helpers
    .toggleFilterProperty(filter, name, term);

  setFilter(productListId, nextFilter);
};

const FilterPanelIndex = (props) => (
  <FilterPanel
    {...props}
    setFilterOption={setFilterOption} />
);

const FilterPanelContainer = connect(
  null,
  {
    setFilter: product_list_actions.setFilter
  }
)(FilterPanelIndex);

export { FilterPanelContainer as FilterPanel };
