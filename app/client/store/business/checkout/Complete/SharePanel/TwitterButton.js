import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './SharePanel.css.json';

export const TwitterButton = ({ promoCode }) => {
  const href = encodeURI([
    'https://twitter.com/intent/tweet?',
    '&hashtags=celebrateeveryday',
    '&text=',
    'Get $10 off wine, liquor and beer on your first @minibardelivery order. Use code: ',
    promoCode,
    '&url=https://minibardelivery.com'
  ].join(''));

  return (
    <a
      className={css([unstyle.a, fonts.common, styles.k, styles.l])}
      href={href}
      rel="noopener noreferrer"
      target="_blank">
      <span
        className={css([
          icon({
            circle: false,
            name: 'twitter'
          }),
          styles.m
        ])}>
      Tweet It Out
      </span>
    </a>
  );
};

TwitterButton.displayName = 'TwitterButton';

TwitterButton.propTypes = {
  promoCode: PropTypes.string.isRequired
};

export default TwitterButton;
