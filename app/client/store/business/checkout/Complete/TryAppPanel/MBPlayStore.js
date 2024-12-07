import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import styles from './TryAppPanel.css.json';

const MBPlayStore = ({ href }) =>
  (
    <a
      className={css([
        styles.playstorelink,
        icon({
          name: 'playStore',
          style: styles.playstoreicon
        })
      ])}
      href={href}
      rel="noopener noreferrer"
      target="_blank"
      title="Get it on Google Play">
      Get it on Google Play
    </a>
  );

MBPlayStore.defaultProps = {
  href: 'https://play.google.com/store/apps/details?id=minibar.android'
};
MBPlayStore.propTypes = {
  href: PropTypes.string
};

export default MBPlayStore;
