import React, { Fragment } from 'react';
import colors from '../MBElements/MBColors.css.json';

const ProductIcon = ({ color, iconOnly, ...props }) => (
  <svg
    version="1"
    viewBox={iconOnly ? '0 0 200 230' : '0 0 200 350'}
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <g fill={color}>
      <path
        /* eslint-disable-next-line max-len */
        d="M70 180c0-95 22-80 22-143-2-2-2-2-2-7 0-8 0-12 10-12s10 4 10 12c0 5 0 5-2 7 0 63 22 48 22 143 0 20 0 30-10 30H80c-10 0-10-10-10-30z" />
      {iconOnly
        ? null
        : (
          <Fragment>
            <rect height="12" rx="3" x="15" y="240" width="170" />
            <rect height="12" rx="3" x="15" y="260" width="170" />
            <rect height="12" rx="3" x="15" y="280" width="65" />
            <rect height="12" rx="3" x="15" y="300" width="65" />
          </Fragment>
        )
      }
    </g>
  </svg>
);

ProductIcon.defaultProps = {
  color: colors.placeholder,
  iconOnly: true
};

export default ProductIcon;
