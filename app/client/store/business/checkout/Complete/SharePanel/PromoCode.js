import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './SharePanel.css.json';

export const PromoCode = ({ promoCode }) =>
  (
    <input
      className={css([unstyle.input, fonts.common, styles.j])}
      defaultValue={promoCode}
      size="13" />
  );

PromoCode.displayName = 'PromoCode';

PromoCode.propTypes = {
  promoCode: PropTypes.string
};

export default PromoCode;
