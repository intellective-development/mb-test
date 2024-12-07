/* @jsxFrag Fragment */

import React, { Fragment, useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Breadcrumbs } from './Breadcrumbs';
import { FilterView } from '../FilterView/FilterView';
import { SortView } from '../SortView/index';
import './FacetBar.scss';

export const FacetBar = ({
  className,
  facets,
  filter,
  productCount,
  productListId,
  sortOptionId,
  ...props
}) => {
  /* Why? https://gist.github.com/gaearon/e7d97cdf38a2907924ea12e4ebdf3c85 */

  const [showView, setShowView] = useState(false);

  useEffect(() => setShowView(true), []);

  return (
    <div
      {...props}
      className={className}>
      <Breadcrumbs
        filter={filter}
        productCount={productCount} />
      {showView && (
        <Fragment>
          <SortView
            position="right"
            productListId={productListId}
            sortOptionId={sortOptionId} />
          <FilterView
            facets={facets}
            filter={filter}
            position="right"
            productListId={productListId} />
        </Fragment>
      )}
    </div>
  );
};

FacetBar.defaultProps = {
  className: 'facet-bar',
  productCount: 0,
  sortOptionId: 'popular_desc'
};

FacetBar.displayName = 'FacetBar';

FacetBar.propTypes = {
  className: PropTypes.string,
  facets: PropTypes.array.isRequired,
  filter: PropTypes.object.isRequired,
  productCount: PropTypes.number,
  productListId: PropTypes.string.isRequired,
  sortOptionId: PropTypes.oneOf([
    'name_asc',
    'name_desc',
    'popular_desc',
    'price_asc',
    'price_desc'
  ])
};
