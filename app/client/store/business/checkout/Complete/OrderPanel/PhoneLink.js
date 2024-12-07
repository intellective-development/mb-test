import { css } from '@amory/style/umd/style';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './OrderPanel.css.json';

export const PhoneLink = () =>
  (
    <a
      className={css([
        unstyle.a,
        fonts.common,
        icon({
          name: 'phone'
        }),
        styles.n
      ])}
      href="tel:855-487-0740">
      (855)&nbsp;487–0740
    </a>
  );

PhoneLink.displayName = 'PhoneLink';

export default PhoneLink;
