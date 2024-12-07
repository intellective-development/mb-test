import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './SharePanel.css.json';

export const FacebookButton = ({ promoCode }) => {
  const APP_ID = 251790598309936;

  const href = encodeURI([
    'https://www.facebook.com/dialog/feed?',
    `&app_id=${APP_ID}`,
    '&display=popup',
    '&link=https://minibardelivery.com/',
    '&quote=',
    'Get $10 off wine, liquor, and beer on your first Minibar Delivery order. Use code: ',
    promoCode
  ].join(''));

  return (
    <a
      className={css([unstyle.a, fonts.common, styles.k, styles.n])}
      href={href}
      rel="noopener noreferrer"
      target="_blank">
      <span
        className={css([
          icon({
            circle: false,
            name: 'facebook'
          }),
          styles.m
        ])}>
        Share on Facebook
      </span>
    </a>
  );
};

FacebookButton.displayName = 'FacebookButton';

FacebookButton.propTypes = {
  promoCode: PropTypes.string.isRequired
};

export default FacebookButton;
