import React from 'react';
import PropTypes from 'prop-types';
import './Breadcrumbs.scss';

export const Breadcrumbs = ({
  className,
  // filter,
  // productCount,
  ...props
}) => (
  <div
    {...props}
    className={className}>
    { }
  </div>
);

Breadcrumbs.defaultProps = {
  className: 'breadcrumbs',
  productCount: 0
};

Breadcrumbs.displayName = 'Breadcrumbs';

Breadcrumbs.propTypes = {
  className: PropTypes.string,
  filter: PropTypes.object.isRequired,
  productCount: PropTypes.number
};
