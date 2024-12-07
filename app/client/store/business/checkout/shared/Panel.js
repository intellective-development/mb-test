import { create, css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';
import fonts from './MBElements/MBFonts.css.json';
import styles from '../Checkout.css.json';

export const Panel = ({
  children,
  className,
  id,
  style,
  ...props
}) => {
  create(fonts);

  return (
    <div
      aria-labelledby={id}
      className={css([
        fonts.common,
        styles.panel,
        style
      ], className)}
      role="group"
      {...props}>
      {children}
    </div>
  );
};

Panel.defaultProps = {
  style: {}
};

Panel.displayName = 'Panel';

Panel.propTypes = {
  children: PropTypes.node,
  className: PropTypes.string,
  id: PropTypes.string,
  style: PropTypes.object
};

export default Panel;
