import React from 'react';
import { connect } from 'react-redux';
import { product_list_actions } from '../../../../business/product_list';
import { SortView } from './SortView';

export const setSortOption = ({
  productListId,
  setSort,
  setToggle,
  term
}) => {
  setSort(productListId, term);
  setToggle(false);
};

const SortViewIndex = (props) => (
  <SortView
    {...props}
    setSortOption={setSortOption} />
);

const SortViewContainer = connect(
  null,
  {
    setSort: product_list_actions.setSort
  }
)(SortViewIndex);

export { SortViewContainer as SortView };
