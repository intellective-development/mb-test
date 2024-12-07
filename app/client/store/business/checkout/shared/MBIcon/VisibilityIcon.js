import React from 'react';
import PropTypes from 'prop-types';

export const VisibilityIcon = ({ color, hide, ...props }) =>
  (
    <svg
      version="1"
      viewBox="0 0 120 120"
      xmlns="http://www.w3.org/2000/svg"
      {...props}>
      <g fill="none" stroke={color} strokeWidth="7">
        <path d="M12 60c23-43 73-43 96 0-23 43-73 43-96 0z" />
        <circle cx="60" cy="60" r="16" />
      </g>
      {hide && (
        <path
          d="M14 96l10 10 82-82-10-10z"
          fill={color}
          stroke="#fff"
          strokeLinejoin="round"
          strokeWidth="7" />
      )}
    </svg>
  );

VisibilityIcon.defaultProps = {
  color: '#808080',
  hide: false
};

VisibilityIcon.propTypes = {
  color: PropTypes.string,
  hide: PropTypes.bool
};

export default VisibilityIcon;
