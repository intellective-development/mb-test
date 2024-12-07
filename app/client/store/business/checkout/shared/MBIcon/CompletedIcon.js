import React from 'react';

const CompletedIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M34 54l21 21 57-57M105 46a47 47 0 0 1-24 56 47 47 0 0 1-59-14 47 47 0 0 1 5-61 47 47 0 0 1 60-5"
      fill="none"
      stroke={color}
      strokeWidth="10" />
  </svg>
);

CompletedIcon.defaultProps = {
  color: '#12781e'
};

export default CompletedIcon;
