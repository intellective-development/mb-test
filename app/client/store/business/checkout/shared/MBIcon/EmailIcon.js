import React from 'react';
import PropTypes from 'prop-types';

import colors from '../MBElements/MBColors.css.json';

const EmailIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M11 30h98v60H11zm0 0l49 40 49-40M11 90l29-24m69 24L80 66"
      fill="none"
      stroke={color}
      strokeLinejoin="round"
      strokeWidth="6" />
  </svg>
);

EmailIcon.defaultProps = {
  color: colors.inlineIcon
};

EmailIcon.propTypes = {
  color: PropTypes.string
};

export default EmailIcon;
