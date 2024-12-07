import { isEmpty, sortBy, has } from 'lodash';
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { filter_helpers } from 'store/business/filter';
import { FilterGroup } from '../FilterGroup/FilterGroup';
import './FilterPanel.scss';

export const FilterPanel = ({ actions, className, facets, filter, productListId, setFilter, setFilterOption }) => {
  const clearAll = () => {
    setFilter(productListId, {
      hierarchy_category: filter.hierarchy_category,
      base: filter.base
    });
  };

  const showClear = () => Object.keys(filter).length > 2;

  useEffect(() => {
    // Select all delivery types by default, per https://minibar.atlassian.net/browse/TECH-1803
    if (!has(filter, 'delivery_type') && !isEmpty(facets)){
      let nextFilter = filter;
      facets
        .find((_) => _.name === 'delivery_type')
        .terms.forEach((term) => {
          nextFilter = filter_helpers.toggleFilterProperty(nextFilter, 'delivery_type', term.term);
        });
      // setFilter(productListId, nextFilter);
    }
  }, [filter, facets, setFilter, productListId]);

  if (isEmpty(facets)){
    return null;
  }

  return (
    <React.Fragment>
      <div className={className}>
        <div className="header">
          <span>Filters</span>
          {showClear() && <button onClick={clearAll}>Clear All</button>}
        </div>
        <div>
          {sortBy(facets, 'index').map(({ display_name, name, terms }) => (
            <FilterGroup
              displayName={display_name}
              filter={filter}
              key={display_name}
              name={name}
              productListId={productListId}
              setFilter={setFilter}
              setFilterOption={setFilterOption}
              terms={terms} />
          ))}
        </div>
      </div>
      {actions.map((i) => (
        <button {...i} className="filter-panel-action" key={i.title} type="button">
          {i.title}
        </button>
      ))}
    </React.Fragment>
  );
};

FilterPanel.defaultProps = {
  actions: [],
  className: 'filter-panel',
  filter: {}
};

FilterPanel.displayName = 'FilterPanel';

FilterPanel.propTypes = {
  actions: PropTypes.array,
  className: PropTypes.string,
  facets: PropTypes.array.isRequired,
  filter: PropTypes.object,
  productListId: PropTypes.string.isRequired,
  setFilter: PropTypes.func.isRequired,
  setFilterOption: PropTypes.func.isRequired
};
