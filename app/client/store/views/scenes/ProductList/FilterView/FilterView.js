/* @jsxFrag Fragment */

import { isEmpty } from 'lodash';
import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { useBounds } from '../hooks/use-bounds';
import { useToggle } from '../hooks/use-toggle';
import { FilterPanel } from '../FilterPanel/index';
import { FilterToggle } from '../FilterToggle/FilterToggle';
import { PopoverView } from '../PopoverView/PopoverView';

export const FilterView = ({
  facets,
  filter,
  productListId,
  ...props
}) => {
  const { bottom, left, ref, width } = useBounds();
  const [toggle, setToggle] = useToggle(false);

  if (isEmpty(facets)){
    return null;
  }

  return (
    <Fragment>
      <FilterToggle
        {...props}
        onClick={() => setToggle()}
        ref={ref}
        toggle={toggle} />
      <PopoverView
        onClick={() => setToggle()}
        toggle={toggle}
        toggleBottom={bottom}
        toggleLeft={left}
        toggleWidth={width}>
        <FilterPanel
          {...props}
          actions={[
            {
              onClick: () => setToggle(),
              title: 'Show Results'
            }
          ]}
          facets={facets}
          filter={filter}
          productListId={productListId} />
      </PopoverView>
    </Fragment>
  );
};

FilterView.displayName = 'FilterView';

FilterView.propTypes = {
  facets: PropTypes.array.isRequired,
  filter: PropTypes.object.isRequired,
  productListId: PropTypes.string.isRequired
};
