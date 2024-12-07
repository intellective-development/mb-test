import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';
import styles from '../Checkout.css.json';

export const Row = ({
  children,
  style,
  ...props
}) => {
  return (
    <div
      className={css([styles.row, style])}
      {...props}>
      {children}
    </div>
  );
};

Row.defaultProps = {
  style: {}
};

Row.displayName = 'Row';

Row.propTypes = {
  children: PropTypes.node,
  style: PropTypes.object
};

export default Row;
