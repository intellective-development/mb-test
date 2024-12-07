import React from 'react';

const CancelIcon = ({ color, ...props }) => (
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
      d="M38 38l44 44m-44 0l44-44"
      stroke="#fff"
      strokeLinecap="round"
      strokeWidth="16" />
  </svg>
);

CancelIcon.defaultProps = {
  color: '#d9534f'
};

export default CancelIcon;
