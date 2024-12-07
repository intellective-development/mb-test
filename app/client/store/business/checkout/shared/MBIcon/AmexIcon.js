import React from 'react';

const AmexIcon = ({
  color,
  ...props
}) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M17 50L8 70h6l2-4h9l2 4h6l-9-20zm3 5h1l3 7h-7zm15 15V50h8l5 13 5-13h8v20h-5V56l-6 14h-4l-6-14v14zm32-20h17v4H72v4h12v4H72v4h12v4H67zm21 0h6l6 7 6-7h6l-9 10 9 10h-6l-6-7-6 7h-6l9-10z"
      fill={color} />
  </svg>
);

AmexIcon.defaultProps = {
  color: '#006fcf'
};

export default AmexIcon;
