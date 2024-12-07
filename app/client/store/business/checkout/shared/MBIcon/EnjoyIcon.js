import React from 'react';
import PropTypes from 'prop-types';

import { colors } from '../../../../views/style/index';

export const EnjoyIcon = ({ color, ...props }) =>
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
          d="M24 29c2-6 23-9 23-6-2 6-21 10-23 6zm0 0c-11 46 59 33 23-6m-7 65c0-5 21-9 23-6 1 4-22 11-23 6zm3-29l7 22M23 42c2-7 30-12 32-7-2 7-31 12-32 7zm34-2c-3 4-9 7-14 8m46-7c4-4 21 2 21 7 0 4-23-4-21-7zm0 0c-35 35 29 58 21 7m-29 4c3-5 28 2 29 8-1 6-30-4-29-8zM68 97c2-5 23 4 21 7-2 4-21-4-21-7zm21-20l-8 20m27-28c-5 1-10 0-15-2"
          strokeWidth="3" />
        <g strokeWidth="2">
          <circle cx="10" cy="68" r="2" />
          <circle cx="16" cy="78" r="2" />
          <circle cx="28" cy="73" r="5" />
          <circle cx="66" cy="30" r="2" />
          <circle cx="75" cy="17" r="2" />
          <circle cx="75" cy="37" r="3" />
          <circle cx="89" cy="18" r="5" />
          <circle cx="99" cy="86" r="1" />
          <circle cx="100" cy="33" r="2" />
          <circle cx="105" cy="94" r="1" />
        </g>
      </g>
    </svg>
  );

EnjoyIcon.defaultProps = {
  color: colors.brandBlack
};

EnjoyIcon.propTypes = {
  color: PropTypes.string
};

export default EnjoyIcon;
