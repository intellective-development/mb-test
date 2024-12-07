import { css } from '@amory/style/umd/style';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';
import React from 'react';
import icon from './MBIcon/MBIcon';
import styles from './MinibarLogo.css.json';

export const MinibarLogo = ({
  href,
  title
}) => (
  <Link
    to={href}
    className={css([
      {
        '@media (max-width: 767px)': icon({
          mobile: true,
          name: 'logo'
        }),
        '@media (min-width: 768px)': icon({
          name: 'logo'
        })
      },
      styles.logo
    ])}
    title={title}>
    {title}
  </Link>
);

MinibarLogo.defaultProps = {
  href: '/store/',
  title: 'Minibar Delivery'
};

MinibarLogo.displayName = 'MinibarLogo';

MinibarLogo.propTypes = {
  href: PropTypes.string,
  title: PropTypes.string
};

export default MinibarLogo;
