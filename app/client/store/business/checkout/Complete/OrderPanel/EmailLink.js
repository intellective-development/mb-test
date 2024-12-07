import { css } from '@amory/style/umd/style';
import React from 'react';

import icon from '../../shared/MBIcon/MBIcon';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './OrderPanel.css.json';

export const EmailLink = () => (
  <a
    className={css([
      unstyle.a,
      fonts.common,
      icon({
        name: 'email'
      }),
      styles.n,
      styles.o
    ])}
    href="mailto:help@minibardelivery.com">
    help@minibardelivery.com
  </a>
);

EmailLink.displayName = 'EmailLink';

export default EmailLink;
