import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';
import unstyle from './MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';

export const EditButton = ({
  children,
  style,
  ...props
}) => (
  <button
    className={css([
      unstyle.button,
      styles.edit,
      style
    ])}
    type="button"
    {...props}>
    {children}
  </button>
);

EditButton.defaultProps = {
  style: {}
};

EditButton.displayName = 'EditButton';

EditButton.propTypes = {
  children: PropTypes.node,
  style: PropTypes.object
};

export default EditButton;
