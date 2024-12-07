import React from 'react';

const DoneIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <circle
      cx="60"
      cy="60"
      fill={color}
      r="52" />
    <path
      d="M34 62l16 16 36-36"
      fill="none"
      stroke="#fff"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="16" />
  </svg>
);

DoneIcon.defaultProps = {
  color: '#5cb85c'
};

export default DoneIcon;
