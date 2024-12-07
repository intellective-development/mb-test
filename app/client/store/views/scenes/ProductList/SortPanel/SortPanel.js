import React from 'react';
import PropTypes from 'prop-types';
import { PopoverView } from '../PopoverView/PopoverView';
import { Criterion } from '../Criterion/Criterion';
import { sortOptions } from '../SortView/sortOptions';
import './SortPanel.scss';

export const SortPanel = ({
  className,
  productListId,
  setSort,
  setSortOption,
  setToggle,
  sortOptionId,
  ...props
}) => (
  <PopoverView
    {...props}>
    <ul
      className={className}>
      {Object.entries(sortOptions).map(([term, { description }]) => (
        <Criterion
          criterion={[sortOptionId]}
          description={description}
          group="sort-criterion"
          key={term}
          onClick={() => setSortOption({
            productListId,
            setSort,
            setToggle,
            term
          })}
          term={term}
          type="radio" />
      ))}
    </ul>
  </PopoverView>
);

SortPanel.defaultProps = {
  className: 'sort-panel',
  sortOptionId: 'popular_desc'
};

SortPanel.displayName = 'SortPanel';

SortPanel.propTypes = {
  className: PropTypes.string,
  productListId: PropTypes.string.isRequired,
  setSort: PropTypes.func.isRequired,
  setSortOption: PropTypes.func.isRequired,
  setToggle: PropTypes.func.isRequired,
  sortOptionId: PropTypes.oneOf([
    'name_asc',
    'name_desc',
    'popular_desc',
    'price_asc',
    'price_desc'
  ])
};
