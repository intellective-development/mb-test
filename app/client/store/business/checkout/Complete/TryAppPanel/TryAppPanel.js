import { css } from '@amory/style/umd/style';
import React from 'react';

import { TryAppImage } from './TryAppImage';
import { TryAppText } from './TryAppText';

import styles from './TryAppPanel.css.json';

export const TryAppPanel = () =>
  (
    <div className={css(styles.a)}>
      <TryAppImage />
      <TryAppText />
    </div>
  );

TryAppPanel.displayName = 'TryAppPanel';

export default TryAppPanel;
