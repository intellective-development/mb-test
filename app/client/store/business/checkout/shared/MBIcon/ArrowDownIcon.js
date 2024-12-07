import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const ArrowDownIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M30 42l30 30 30-30"
      fill="none"
      stroke={color}
      strokeWidth="12" />
  </svg>
);

ArrowDownIcon.defaultProps = {
  color: colors.inlineIcon
};

export default ArrowDownIcon;
