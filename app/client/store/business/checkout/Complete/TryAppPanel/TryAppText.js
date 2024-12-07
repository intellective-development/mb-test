import { css } from '@amory/style/umd/style';
import React from 'react';

import MBAppStore from './MBAppStore';
import MBPlayStore from './MBPlayStore';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './TryAppPanel.css.json';

export const TryAppText = () =>
  (
    <div className={css([fonts.common, styles.d])}>
      <div className={css(styles.e)}>
        Have You Tried the App?
      </div>
      <div className={css(styles.f)}>
        Download our
        {' '}
        <a
          className={css([unstyle.a, styles.g])}
          href="https://itunes.apple.com/us/app/minibar-delivery/id720850888?mt=8">
          iOS
        </a>
        {' '}
        and
        {' '}
        <a
          className={css([unstyle.a, styles.g])}
          href="https://play.google.com/store/apps/details?id=minibar.android">
          Android
        </a>
        {' '}
        app and order in a few easy taps.
      </div>
      <div className={css(styles.h)}>
        <MBAppStore />
      </div>
      <div className={css(styles.h)}>
        <MBPlayStore />
      </div>
    </div>
  );

export default TryAppText;
