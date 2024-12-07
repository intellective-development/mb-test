import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const StorefrontIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M27 23v25c2 6 14 6 16 0M13 23c-7 23 1 38 14 25m16-25v25c3 6 15 6 17 0m33-25v25c-3 6-14 6-16 0m30-25c7 23-1 38-14 25M77 23v25c-3 6-15 6-17 0m0-25v25M13 10h94v13H13zm0 40v60h94V50M25 65h38v32H25zm49 45V65h21v45"
      fill="none"
      stroke={color}
      strokeWidth="5" />
  </svg>
);

StorefrontIcon.defaultProps = {
  color: colors.inlineIcon
};

export default StorefrontIcon;
