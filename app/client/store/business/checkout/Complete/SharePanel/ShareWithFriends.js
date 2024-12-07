import { css } from '@amory/style/umd/style';
import React from 'react';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import styles from './SharePanel.css.json';

export const ShareWithFriends = () =>
  (
    <div className={css([fonts.common, styles.b])}>
      <div className={css(styles.c)}>
        Share with Friends
      </div>
      <div className={css(styles.d)}>
        Get free drinks for spreading the word about Minibar Delivery.
      </div>
    </div>
  );

ShareWithFriends.displayName = 'ShareWithFriends';

export default ShareWithFriends;
