import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import styles from './TryAppPanel.css.json';

const MBAppStore = ({ href, ...props }) =>
  (
    <a
      {...props}
      className={css([
        styles.appstorelink,
        icon({
          name: 'appStore',
          style: styles.appstoreicon
        })
      ])}
      href={href}
      rel="noopener noreferrer"
      target="_blank"
      title="Download on the App Store">
      Download on the App Store
    </a>
  );

MBAppStore.defaultProps = {
  href: 'https://itunes.apple.com/us/app/minibar-delivery/id720850888?mt=8'
};

MBAppStore.propTypes = {
  href: PropTypes.string
};

export default MBAppStore;
