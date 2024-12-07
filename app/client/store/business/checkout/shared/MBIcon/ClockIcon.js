import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const ClockIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <circle
      cx="60"
      cy="60"
      fill="none"
      r="47"
      stroke={color}
      strokeWidth="4" />
    <path
      d="M62 28v34L44 80"
      fill="none"
      stroke={color}
      strokeWidth="5" />
  </svg>
);

ClockIcon.defaultProps = {
  color: colors.inlineIcon
};

export default ClockIcon;
