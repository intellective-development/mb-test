/* @jsxFrag Fragment */

import React, { Fragment } from 'react';
import { useBounds } from '../hooks/use-bounds';
import { useToggle } from '../hooks/use-toggle';
import { SortPanel } from '../SortPanel/SortPanel';
import { SortToggle } from '../SortToggle/SortToggle';
import { sortOptions } from './sortOptions';

export const SortView = ({
  productListId,
  setSort,
  setSortOption,
  sortOptionId,
  ...props
}) => {
  const { bottom, left, ref, width } = useBounds();
  const [toggle, setToggle] = useToggle(false);

  return (
    <Fragment>
      <SortToggle
        {...props}
        onClick={() => setToggle()}
        ref={ref}
        sortOptions={sortOptions}
        sortOptionId={sortOptionId}
        toggle={toggle} />
      <SortPanel
        {...props}
        onClick={() => setToggle()}
        productListId={productListId}
        setSort={setSort}
        setSortOption={setSortOption}
        setToggle={setToggle}
        sortOptionId={sortOptionId}
        toggle={toggle}
        toggleBottom={bottom}
        toggleLeft={left}
        toggleWidth={width} />
    </Fragment>
  );
};

SortView.displayName = 'SortView';
