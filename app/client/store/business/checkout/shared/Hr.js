import { css } from '@amory/style/umd/style';
import React from 'react';
import unstyle from './MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';

export const Hr = () => (
  <hr className={css([unstyle.hr, styles.hr])} />
);

export default Hr;
