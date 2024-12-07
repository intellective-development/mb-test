import React from 'react';

const VisaIcon = ({
  color, ...props
}) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      /* eslint-disable-next-line max-len */
      d="M24.9 46.8c-.5-2-2-2.5-3.7-2.5h-13l-.2.6c10.2 2.5 17 8.4 19.7 15.6z"
      fill="#faa61a" />
    <path
      /* eslint-disable-next-line max-len */
      d="M58 44.5h-8.3l-5.4 31.1h8.5zm-20.7.1L29 65.7l-.9-3.2a33.2 33.2 0 0 0-11.7-12.8L24 75.5h9l13.2-31zm37.9 5.9c2.8 0 4.8.5 6.4 1.2l.7.3 1.2-6.7c-1.7-.6-4.3-1.3-7.6-1.3-8.4 0-14.2 4.2-14.3 10.2 0 4.5 4.2 7 7.4 8.5 3.3 1.5 4.4 2.4 4.4 3.8 0 2-2.6 3-5 3-3.4 0-5.2-.4-8-1.6l-1.1-.5-1.2 7c2 .8 5.6 1.6 9.4 1.6 8.9 0 14.7-4.1 14.7-10.6 0-3.5-2.2-6.2-7-8.4-3-1.5-4.8-2.4-4.8-3.9 0-1.2 1.5-2.6 4.8-2.6zm30-5.9h-6.6c-2 0-3.5.5-4.4 2.5L81.6 75.6h9l1.7-4.7h10.8l1 4.7h7.9zm-10.5 20l3.4-8.7 1.1-3 .6 2.7 2 9z"
      fill={color} />
  </svg>
);

VisaIcon.defaultProps = {
  color: '#00579f'
};

export default VisaIcon;
