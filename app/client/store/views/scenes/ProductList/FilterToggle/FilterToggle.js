import React, { forwardRef } from 'react';
import PropTypes from 'prop-types';
import './FilterToggle.scss';

export const FilterToggle = forwardRef(
  ({
    children,
    className,
    toggle,
    ...props
  }, ref) => {
    const classNames = [className, toggle ? 'active' : null]
      .filter(Boolean)
      .join(' ');

    return (
      <button
        {...props}
        className={classNames}
        ref={ref}
        type="button">
        {children}
      </button>
    );
  }
);

FilterToggle.defaultProps = {
  children: 'Filter',
  className: 'filter-toggle',
  toggle: false
};

FilterToggle.displayName = 'FilterToggle';

FilterToggle.propTypes = {
  children: PropTypes.node,
  className: PropTypes.string,
  toggle: PropTypes.bool
};
