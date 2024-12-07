import { css } from '@amory/style/umd/style';
import React from 'react';
import { MBLink } from 'store/views/elements';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';

import styles from './ContinueShopping.css.json';

export const ContinueShopping = () => (
  <MBLink.Text className={css([unstyle.button, fonts.common, styles.a])} href="/store/">
    Continue Shopping
  </MBLink.Text>
);

export default ContinueShopping;
