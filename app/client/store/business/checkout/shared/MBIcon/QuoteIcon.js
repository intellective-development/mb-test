import React from 'react';
import PropTypes from 'prop-types';

import { colors } from '../../../../views/style/index';

export const QuoteIcon = ({ color, ...props }) =>
  (
    <svg
      version="1"
      viewBox="0 0 120 120"
      xmlns="http://www.w3.org/2000/svg"
      xmlnsXlink="http://www.w3.org/1999/xlink"
      {...props}>
      <path
        d="M56 24v10c-16 0-24 6-24 20 34 0 34 42 0 42-16 0-28-24-22-42 7-21 22-30 46-30z"
        fill={color}
        id="a" />
      <use
        height="100%"
        transform="translate(54)"
        width="100%"
        xlinkHref="#a" />
    </svg>
  );

QuoteIcon.defaultProps = {
  color: colors.brandRed
};

QuoteIcon.propTypes = {
  color: PropTypes.string
};

export default QuoteIcon;
