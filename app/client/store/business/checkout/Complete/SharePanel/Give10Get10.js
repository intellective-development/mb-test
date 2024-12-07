import { css } from '@amory/style/umd/style';
import React from 'react';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import styles from './SharePanel.css.json';

export const Give10Get10 = () =>
  (
    <div className={css([fonts.common, styles.f])}>
      <div className={css(styles.g)}>
        <strong className={css(styles.h)}>
          Give $10, get $10
        </strong>
        , when they use your referral code on
        their first order.
      </div>
    </div>
  );

Give10Get10.displayName = 'Give10Get10';

export default Give10Get10;
