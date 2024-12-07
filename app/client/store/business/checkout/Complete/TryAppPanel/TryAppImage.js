import { css } from '@amory/style/umd/style';
import React from 'react';

import styles from './TryAppPanel.css.json';

export const TryAppImage = () =>
  (
    <div className={css(styles.b)}>
      <img
        alt="Minibar Delivery app"
        className={css(styles.c)}
        src="/assets/checkout/iphone.png" />
    </div>
  );

export default TryAppImage;
