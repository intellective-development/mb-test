import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const CircleIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <circle
      cx="60"
      cy="60"
      fill={color}
      r="50"
      strokeWidth="4" />
  </svg>
);

CircleIcon.defaultProps = {
  color: colors.inlineIcon
};

export default CircleIcon;
