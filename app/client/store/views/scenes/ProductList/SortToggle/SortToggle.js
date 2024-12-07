import React, { forwardRef } from 'react';
import PropTypes from 'prop-types';
import './SortToggle.scss';

export const SortToggle = forwardRef(
  ({ className, sortOptionId, sortOptions, toggle, ...props }, ref) => {
    const classNames = [className, toggle ? 'active' : null]
      .filter(Boolean)
      .join(' ');

    const title = sortOptions[sortOptionId].title || 'Sort';

    return (
      <button
        {...props}
        className={classNames}
        ref={ref}
        type="button">
        {title}
      </button>
    );
  }
);

SortToggle.defaultProps = {
  className: 'sort-toggle',
  sortOptionId: 'popular_desc',
  toggle: false
};

SortToggle.displayName = 'SortToggle';

SortToggle.propTypes = {
  className: PropTypes.string,
  sortOptionId: PropTypes.oneOf([
    'name_asc',
    'name_desc',
    'popular_desc',
    'price_asc',
    'price_desc'
  ]),
  toggle: PropTypes.bool
};
