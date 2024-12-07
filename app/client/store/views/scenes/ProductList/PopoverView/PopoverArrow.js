/* eslint-disable no-mixed-operators */

import React from 'react';
import PropTypes from 'prop-types';
import './PopoverView.scss';

export const PopoverArrow = ({
  arrowWidth,
  className,
  popoverLeft,
  toggleLeft,
  toggleWidth,
  ...props
}) => (
  <svg
    {...props}
    className={className}
    style={{
      left: `${toggleLeft - popoverLeft + toggleWidth / 2 - arrowWidth / 2}px`
    }}
    version="1"
    viewBox="8 8 104 52"
    xmlns="http://www.w3.org/2000/svg">
    <path
      d="M8 60c24-8 36-48 52-48s28 40 52 48v52H8z" />
  </svg>
);

PopoverArrow.defaultProps = {
  arrowWidth: 30,
  className: 'popover-arrow',
  popoverLeft: 0,
  toggleLeft: 0,
  toggleWidth: 0
};

PopoverArrow.displayName = 'PopoverArrow';

PopoverArrow.propTypes = {
  arrowWidth: PropTypes.number,
  className: PropTypes.string,
  popoverLeft: PropTypes.number,
  toggleLeft: PropTypes.number,
  toggleWidth: PropTypes.number
};
