import React from 'react';

const DiscoverIcon = ({
  color,
  ...props
}) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <g
      fill="none"
      stroke={color}
      strokeWidth="3">
      <path
        d="M9.5 53v13.5c14 2 14-15.5 0-13.5zM25 51.5V68m13-13.5c-6.5-5.5-11.5 3-3.7 5.1C41.5 61.6 36 72 29 64m23.5-10C38 48 38 72 52.5 66m45-13H90v13.5h7.5m-7.5-7h7.5M101 68V53c10.5-2 10 9.5 0 7.5h4l5 7.5" />
      <path
        d="M73 52l6 15.5L85.5 52"
        strokeLinejoin="bevel" />
    </g>
    <circle
      cx="63"
      cy="60"
      fill="#f58220"
      r="8.6" />
  </svg>
);

DiscoverIcon.defaultProps = {
  color: '#231f20'
};

export default DiscoverIcon;
