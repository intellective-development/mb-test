import { css } from '@amory/style/umd/style';
import React from 'react';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import styles from './OrderPanel.css.json';

export const AccountCreated = () => (
  <div className={css([fonts.common, styles.a, styles.r])}>
    <div className={css(styles.b)}>Account Created</div>
    <div className={css(styles.c)}>Your account was created. You&lsquo;ll receive an email confirmation shortly.</div>
  </div>
);

AccountCreated.displayName = 'AccountCreated';

export default AccountCreated;
