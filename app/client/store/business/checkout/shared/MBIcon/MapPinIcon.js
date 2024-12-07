import React, { Fragment } from 'react';
import PropTypes from 'prop-types';

import { colors } from '../../../../views/style/index';

export const MapPinIcon = ({ color, variant, ...props }) =>
  (
    <svg
      version="1"
      viewBox="0 0 120 120"
      xmlns="http://www.w3.org/2000/svg"
      {...props}>
      <g fill="none" stroke={color} strokeWidth="5">
        {variant === 1 ? (
          <Fragment>
            <circle cx="60" cy="45" r="15" />
            <path d="M60 108c118-130-118-130 0 0z" />
          </Fragment>
        ) : null}
        {variant === 2 ? (
          <Fragment>
            <circle cx="60" cy="40" r="11" />
            <path d="M60 110C48 88 36 66 30 40c0-40 60-40 60 0-6 26-18 48-30 70z" />
          </Fragment>
        ) : null}
        {variant === 3 ? (
          <Fragment>
            <circle cx="60" cy="40" r="11" />
            <path d="M60 110c-95-133 95-133 0 0z" />
          </Fragment>
        ) : null}
      </g>
    </svg>
  );

MapPinIcon.defaultProps = {
  color: colors.inlineIcon,
  variant: 1
};

MapPinIcon.propTypes = {
  color: PropTypes.string,
  variant: PropTypes.number
};

export default MapPinIcon;
