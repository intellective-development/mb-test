import { css } from '@amory/style/umd/style';
import React, { forwardRef } from 'react';

import { useToggle } from '../../shared/use-toggle';

import icon from '../../shared/MBIcon/MBIcon';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import styles from './OrderPanel.css.json';

export const PasswordInput = forwardRef((_props, ref) => {
  const [toggle, setToggle] = useToggle(true);

  return (
    <div className={css(styles.i)}>
      <input
        className={css([unstyle.input, fonts.common, styles.j])}
        placeholder="password"
        ref={ref}
        size="8"
        type={toggle ? 'password' : 'text'}
        {..._props} />
      <button
        className={css([
          unstyle.button,
          icon({
            hide: toggle,
            name: 'visibility'
          }),
          styles.k
        ])}
        onClick={setToggle}
        type="button" />
    </div>
  );
});

PasswordInput.displayName = 'PasswordInput';

export default PasswordInput;
