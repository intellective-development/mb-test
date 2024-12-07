import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const MinibarLogo = ({ color, mobile, ...props }) => (
  <svg
    version="1.1"
    viewBox={mobile ? '0 40 120 40' : '0 0 120 120'}
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    {mobile
      ? null
      : <circle cx="60" cy="60" fill={color} r="60" />
    }
    <path
      /* eslint-disable-next-line max-len */
      d="M90 43v2H30v-2zM22.4 56.7v10h2V52.5h-2l-4.9 9-4.9-9h-2v14.4h2v-10l5 8.7 4.8-8.8zm7.8-4.3h2.1v14.4h-2.1zm20.4 14.4V52.4h-2.1v11l-8.6-11h-2v14.4h2v-11l8.6 11zm5.5-14.4h2.1v14.4h-2.1zm7.3 0v14.4h8.2c2.8 0 5-1.4 5-4.2 0-1.8-1.2-3-2-3.4.5-.5 1.3-1.3 1.3-2.9 0-2.7-2.1-3.9-4.3-3.9zm2.2 2.1h6c1.5 0 2.2.7 2.2 1.8 0 1.3-.7 2.1-2.2 2.1h-6zm0 6h6c2.2 0 2.9.8 2.9 2.1 0 1.4-1 2.1-2.9 2.1h-6zm22-8.2l-2.5.1-6.5 14.4H81l2-4.8h6.5l2 4.7H94zM86.3 55l2.2 5H84zm10.8-2.6v14.4h2v-6h5.4l2.9 6h2.3l-3-6c1.3-.2 3.3-1.2 3.3-4.3 0-3-2.2-4.1-4.5-4.1zm2 2.1h6.4c1.2 0 2.5.4 2.5 2 0 1.4-1 2.2-2.5 2.2h-6.4zM90 74v2H30v-2z"
      fill={mobile ? color : '#fff'} />
  </svg>
);

MinibarLogo.defaultProps = {
  color: colors.brandBlack,
  mobile: false
};

export default MinibarLogo;
