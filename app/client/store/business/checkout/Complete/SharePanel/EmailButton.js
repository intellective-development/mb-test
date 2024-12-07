import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './SharePanel.css.json';

export const EmailButton = ({ promoCode }) => {
  const href = encodeURI([
    'mailto:?',
    '&subject=',
    '&body=',
    'Get $10 off wine, liquor, and beer on your first Minibar Delivery order. Use code: ',
    promoCode,
    ' <https://minibardelivery.com/>'
  ].join(''));

  return (
    <a
      className={css([unstyle.a, fonts.common, styles.k, styles.o])}
      href={href}>
      <span
        className={css([
          icon({
            color: '#fff',
            name: 'email'
          }),
          styles.p
        ])}>
        Email Friends
      </span>
    </a>
  );
};

EmailButton.displayName = 'EmailButton';

EmailButton.propTypes = {
  promoCode: PropTypes.string.isRequired
};

export default EmailButton;
