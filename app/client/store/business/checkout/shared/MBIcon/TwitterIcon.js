import React from 'react';
import PropTypes from 'prop-types';

import colors from '../MBElements/MBColors.css.json';

const TwitterIcon = ({
  active, circle, color, hover, ...props
}) =>
  (
    <svg
      version="1"
      viewBox="0 0 120 120"
      xmlns="http://www.w3.org/2000/svg"
      {...props}>
      {circle && (
        <circle
          cx="60"
          cy="60"
          fill={active ? hover : color}
          r="60" />
      )}
      <path
      /* eslint-disable-next-line max-len */
        d="M87 41c3-2 5-5 6-8-3 1-5 2-9 3-10-10-27-3-25 13-12-1-22-6-29-15-4 7-2 15 4 19-2 0-4 0-6-1 0 6 4 13 11 14-2 0-4 1-6 0 2 6 7 10 13 10-6 5-14 7-21 6 32 18 63-4 63-36 3-2 5-5 7-8-2 1-5 2-8 3z"
        fill="#fff" />
    </svg>
  );

TwitterIcon.defaultProps = {
  active: false,
  circle: true,
  color: colors.actionIcon,
  hover: '#1da1f2'
};

TwitterIcon.propTypes = {
  active: PropTypes.bool,
  circle: PropTypes.bool,
  color: PropTypes.string,
  hover: PropTypes.string
};

export default TwitterIcon;
