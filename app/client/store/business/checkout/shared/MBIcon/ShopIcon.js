import React from 'react';
import PropTypes from 'prop-types';

import { colors } from '../../../../views/style/index';

export const ShopIcon = ({ color, ...props }) =>
  (
    <svg
      version="1"
      viewBox="0 0 120 120"
      xmlns="http://www.w3.org/2000/svg"
      {...props}>
      <g
        fill="none"
        stroke={color}
        strokeLinecap="round"
        strokeLinejoin="round">
        <path
          /* eslint-disable-next-line max-len */
          d="M85 52v52c0 4-2 6-6 6H41c-4 0-6-2-6-6V16c0-4 2-6 6-6h38c4 0 6 2 6 6v12M53 15h8m6 0v0m-32 5h50m16 18a12 12 0 01-8 13 12 12 0 01-14-4 12 12 0 011-15 12 12 0 0115-2m-11 8l5 5 15-15M35 96h50"
          strokeWidth="4" />
        <path
          d="M62.5 39v13c4 4 4 4 4 24h-13c0-20 0-20 4-24V39zm-5 5h5"
          strokeWidth="3" />
        <circle
          cx="60"
          cy="103"
          r="3"
          strokeWidth="2" />
      </g>
    </svg>
  );

ShopIcon.defaultProps = {
  color: colors.brandBlack
};

ShopIcon.propTypes = {
  color: PropTypes.string
};

export default ShopIcon;
