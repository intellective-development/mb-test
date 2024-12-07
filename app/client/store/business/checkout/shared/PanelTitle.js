import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';
import icon from './MBIcon/MBIcon';
import unstyle from './MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';

export const PanelTitle = ({
  children,
  id,
  isComplete,
  ...props
}) => (
  <h3
    className={css([
      unstyle.h,
      isComplete ? icon({ name: 'completed' }) : {},
      styles.title
    ])}
    id={id}
    {...props}>
    {children}
  </h3>
);

PanelTitle.defaultProps = {
  isComplete: false
};

PanelTitle.displayName = 'PanelTitle';

PanelTitle.propTypes = {
  children: PropTypes.node,
  id: PropTypes.string,
  isComplete: PropTypes.bool
};

export default PanelTitle;
