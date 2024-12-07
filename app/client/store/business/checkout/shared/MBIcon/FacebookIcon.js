import React from 'react';
import PropTypes from 'prop-types';

import colors from '../MBElements/MBColors.css.json';

const FacebookIcon = ({
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
        d="M53 95V63H42V51h11V41c0-10 6-16 16-16h9v12h-6c-6 0-7 2-7 6v8h13l-2 12H65v32z"
        fill="#fff" />
    </svg>
  );

FacebookIcon.defaultProps = {
  active: false,
  circle: true,
  color: colors.actionIcon,
  hover: '#3b5998'
};

FacebookIcon.propTypes = {
  active: PropTypes.bool,
  circle: PropTypes.bool,
  color: PropTypes.string,
  hover: PropTypes.string
};

export default FacebookIcon;
