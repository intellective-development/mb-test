import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const SecureIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M35 43c0-39 50-39 50 0M25 48h70v59H25z"
      fill="none"
      stroke={color}
      strokeLinejoin="round"
      strokeWidth="10" />
    <circle
      cx="60"
      cy="77"
      fill={color}
      r="10" />
  </svg>
);

SecureIcon.defaultProps = {
  color: colors.inlineIcon
};

export default SecureIcon;
