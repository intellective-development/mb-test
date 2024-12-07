import { get, has } from 'lodash';
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { Criterion } from '../Criterion/Criterion';
import { useToggle } from '../hooks/use-toggle';
import './FilterGroup.scss';

export const FilterGroup = ({ className, displayName, filter, name, productListId, setFilter, setFilterOption, terms, ...props }) => {
  const [toggle, setToggle] = useToggle(has(filter, name));
  useEffect(() => {
    // Expand the panel if selected by default, per https://minibar.atlassian.net/browse/TECH-1803
    if (has(filter, name) && !toggle){
      setToggle();
    }
  }, [filter, name, toggle, setToggle]);

  return (
    <fieldset aria-expanded={toggle} className={className}>
      <legend onClick={() => setToggle()}>{displayName}</legend>
      <ul
        style={{
          gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr)'
        }}>
        {terms.map(({ description, term }) => (
          <Criterion
            {...props}
            criterion={get(filter, name)}
            description={description}
            filter={filter}
            key={term}
            name={name}
            onClick={() =>
              setFilterOption({
                filter,
                name,
                productListId,
                setFilter,
                term
              })
            }
            term={term} />
        ))}
      </ul>
    </fieldset>
  );
};

FilterGroup.defaultProps = {
  className: 'filter-group'
};

FilterGroup.displayName = 'FilterGroup';

FilterGroup.propTypes = {
  className: PropTypes.string,
  displayName: PropTypes.string.isRequired,
  filter: PropTypes.object.isRequired,
  name: PropTypes.oneOf(['selected_supplier', 'hierarchy_type', 'hierarchy_subtype', 'country', 'volume', 'container_type', 'price', 'delivery_type']).isRequired,
  productListId: PropTypes.string.isRequired,
  setFilter: PropTypes.func.isRequired,
  setFilterOption: PropTypes.func.isRequired,
  terms: PropTypes.array.isRequired
};
