import React from 'react';
import PropTypes from 'prop-types';

import colors from '../MBElements/MBColors.css.json';

const PhoneIcon = ({ color, ...props }) =>
  (
    <svg
      version="1"
      viewBox="0 0 120 120"
      xmlns="http://www.w3.org/2000/svg"
      {...props}>
      <path
      /* eslint-disable-next-line max-len */
        d="M42 78a97 97 0 0 1-31-48c0-8 17-18 19-19 5-1 15 20 17 25 1 4-7 11-7 13-1 3 8 13 13 18M42 78c15 15 29 26 48 31 8 0 18-17 19-19 1-5-20-15-25-17-4-1-11 7-13 7-3 1-13-8-18-13"
        fill="none"
        stroke={color}
        strokeWidth="7" />
    </svg>
  );

PhoneIcon.defaultProps = {
  color: colors.inlineIcon
};

PhoneIcon.propTypes = {
  color: PropTypes.string
};

export default PhoneIcon;
