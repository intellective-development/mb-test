import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './OrderPanel.css.json';

export const CreateButton = ({ disabled, onClick }) => (
  <button
    aria-disabled={disabled ? true : null}
    className={css([unstyle.button, fonts.common, styles.l])}
    onClick={onClick}
    tabIndex={disabled ? -1 : null}
    type="button">
    Create Account
  </button>
);

CreateButton.defaultProps = {
  disabled: false
};

CreateButton.displayName = 'CreateButton';

CreateButton.propTypes = {
  disabled: PropTypes.bool,
  onClick: PropTypes.func.isRequired
};

export default CreateButton;
